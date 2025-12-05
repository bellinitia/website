require 'date'
require 'json'

module Jekyll
  class PublicationPageGenerator < Generator
    safe true
    priority :low

    def generate(site)
      data = site.data['publications']
      return unless data && data.is_a?(Array)

      data.each do |pub|
        slug = make_slug(pub['title'] || pub['id'])
        site.collections['publications'].docs << build_doc(site, pub, slug)
      end
    end

    private

    def make_slug(text)
      return 'untitled' unless text
      text.downcase.strip
          .gsub(/\s+/, '-')
          .gsub(/[^\w-]/, '')
    end

    def build_doc(site, pub, slug)
      collection = site.collections['publications']
      path       = File.join(collection.relative_directory, "#{slug}.md")

      doc = Jekyll::Document.new(path, { :site => site, :collection => collection })

      data = {}

      # Title
      data['title'] = pub['title']

      # Authors: "Family, Given"
      # Prefer 'author', but fallback to 'container-author' if author is missing
      author_list = pub['author'] || pub['container-author']
      
      if author_list
        data['authors'] = author_list.map { |a|
          [a['family'], a['given']].compact.join(', ')
        }
      end

      # Date
      data['date'] = parse_date(pub['issued'])

      # Venue / publisher / container
      if pub['type'] == 'chapter'
        # Define variables explicitly for the debug check
        publisher = pub['publisher']
        container = pub['container-title']

        # DEBUG: Force the output to tell us what it sees
        if publisher && !publisher.empty?
           data['venue'] = publisher
        else
           data['venue'] = "DEBUG: Publisher is EMPTY. Container is: #{container}"
        end
      else
        # For everything else, keep the existing logic
        data['venue'] = pub['container-title'] || pub['publisher']
      end

      # Volume / issue / pages
      data['volume']    = pub['volume']
      data['issue']     = pub['issue']
      firstpage, lastpage = split_pages(pub['page'])
      data['firstpage'] = firstpage
      data['lastpage']  = lastpage

      # --- FIX START: URL and DOI Handling ---
      data['doi'] = pub['DOI']
      
      # 1. Check for explicit URL (Uppercase key from your JSON)
      if pub['URL']
        data['paperurl'] = pub['URL']
      # 2. Fallback: if no URL but DOI exists, create a DOI link
      elsif pub['DOI']
        data['paperurl'] = "https://doi.org/#{pub['DOI']}"
      end
      # --- FIX END ---

      # Abstract & language
      data['abstract'] = pub['abstract']
      data['language'] = pub['language'] || 'en'

      # Category / extra
      cat, extra, book_title, editors = map_type_and_extras(pub)
      data['category']   = cat
      data['extra']      = extra if extra
      data['book_title'] = book_title if book_title
      data['editors']    = editors   if editors && !editors.empty?

      # --- FIX START: PDF Extraction ---
      # Check both 'note' and 'extra' fields combined to ensure we don't miss it
      pdf_url = extract_pdf_url(pub['note'], pub['extra'])
      data['pdf'] = pdf_url if pdf_url
      # --- FIX END ---

      # Layout and standard front matter fields
      data['collection']      = 'publications'
      data['author_profile']  = true
      data['share']           = true
      data['comments']        = true

      # Excerpt: use abstract as excerpt if present
      data['excerpt'] = pub['abstract'] if pub['abstract']

      # Put abstract into the main content body so it appears on the page
      doc.content = pub['abstract'] if pub['abstract']

      doc.merge_data!(data)
      doc
    end

    def parse_date(issued)
      return nil unless issued && issued['date-parts'].is_a?(Array)
      parts = issued['date-parts'].first
      year  = parts[0].to_i
      month = (parts[1] || 1).to_i
      day   = (parts[2] || 1).to_i
      Date.new(year, month, day)
    rescue
      nil
    end

    def split_pages(pages)
      return [nil, nil] unless pages.is_a?(String)
      parts = pages.split(/[–-]/) # handle hyphen or en dash
      first = parts[0]&.strip
      last  = parts[1]&.strip
      [first, last]
    end

      def map_type_and_extras(pub)
      csl_type = pub['type']
      cat   = 'other'
      extra = nil
      book_title = nil
      editors = nil

      case csl_type
      when 'book'
        cat = 'books'
      when 'article-journal'
        cat = 'journal'
      when 'paper-conference'
        cat = 'conference'
      when 'chapter'
        cat   = 'chapter'
        book_title = pub['container-title']
        
        # Explicitly fetch editors
        if pub['editor']
          editors = pub['editor'].map { |e|
            [e['given'], e['family']].compact.join(' ') # e.g. "Lin Young"
          }
        end
      when 'thesis'
        cat   = 'books'
        extra = 'thesis'
      end

      [cat, extra, book_title, editors]
    end


    # UPDATED: Helper to extract PDF from either note or extra
    def extract_pdf_url(note_field, extra_field)
      # Combine them into one string to search
      search_text = [note_field, extra_field].compact.join("\n")
      
      # Regex to find "PDF:" followed by the path
      # This handles cases where PDF is on the second line of the note
      if match = search_text.match(/PDF:\s*(.+)$/)
        return match[1].strip
      end
      
      nil
    end
  end
end
