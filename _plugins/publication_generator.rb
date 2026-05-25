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


    # Parses all key: value lines from note and extra fields into a single hash.
    # Handles multiple lines, e.g.:
    #   PDF: /files/paper.pdf
    #   type: other
    #   _eprint: https://doi.org/...
    def parse_note_fields(pub)
      search_text = [pub['note'], pub['extra']].compact.join("\n")
      # Handle both real newlines and literal \n from JSON export
      search_text = search_text.gsub('\n', "\n")
      fields = {}
      search_text.each_line do |line|
        if match = line.match(/^([^:]+):\s*(.+)$/)
          key   = match[1].strip.downcase
          value = match[2].strip
          fields[key] = value
        end
      end
      fields
    end


    def build_doc(site, pub, slug)
      collection = site.collections['publications']
      path       = File.join(collection.relative_directory, "#{slug}.md")

      doc = Jekyll::Document.new(path, { :site => site, :collection => collection })

      data = {}

      # Parse all note/extra fields once, reuse throughout
      note_fields = parse_note_fields(pub)

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
        publisher = pub['publisher']
        container = pub['container-title']
        if publisher && !publisher.empty?
          data['venue'] = publisher
        else
          data['venue'] = "DEBUG: Publisher is EMPTY. Container is: #{container}"
        end
      else
        data['venue'] = pub['container-title'] || pub['publisher']
      end

      # Volume / issue / pages
      data['volume']    = pub['volume']
      data['issue']     = pub['issue']
      firstpage, lastpage = split_pages(pub['page'])
      data['firstpage'] = firstpage
      data['lastpage']  = lastpage

      # URL and DOI Handling
      data['doi'] = pub['DOI']
      if pub['URL']
        data['paperurl'] = pub['URL']
      elsif pub['DOI']
        data['paperurl'] = "https://doi.org/#{pub['DOI']}"
      end

      # Abstract & language
      data['abstract'] = pub['abstract']
      data['language'] = pub['language'] || 'en'

      # Category / extra — type can be overridden via "type: other" in note/extra
      cat, extra, book_title, editors = map_type_and_extras(pub, note_fields)
      data['category']   = cat
      data['extra']      = extra if extra
      data['book_title'] = book_title if book_title
      data['editors']    = editors if editors && !editors.empty?

      # PDF extraction from note/extra fields
      pdf_url = note_fields['pdf']
      data['pdf'] = pdf_url if pdf_url

      # Embargo duration in months (defaults to 12 if not set)
      embargo_months = note_fields['embargo']
      data['embargo_months'] = embargo_months.to_i if embargo_months

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
      parts = pages.split(/[–-]/)
      first = parts[0]&.strip
      last  = parts[1]&.strip
      [first, last]
    end


    def map_type_and_extras(pub, note_fields = {})
      # Allow overriding CSL type via "type: other" (or any value) in note/extra
      csl_type = note_fields['type'] || pub['type']
      cat        = 'other'
      extra      = nil
      book_title = nil
      editors    = nil

      case csl_type
      when 'book'
        cat = 'books'
      when 'article-journal'
        cat = 'journal'
      when 'paper-conference'
        cat = 'conference'
      when 'chapter'
        cat        = 'chapter'
        book_title = pub['container-title']
        if pub['editor']
          editors = pub['editor'].map { |e|
            [e['given'], e['family']].compact.join(' ')
          }
        end
      when 'thesis'
        cat   = 'books'
        extra = 'thesis'
      end

      [cat, extra, book_title, editors]
    end

  end
end