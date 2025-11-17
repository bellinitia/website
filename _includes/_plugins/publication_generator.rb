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
      if pub['author']
        data['authors'] = pub['author'].map { |a|
          [a['family'], a['given']].compact.join(', ')
        }
      end

      # Date
      data['date'] = parse_date(pub['issued'])

      # Venue / publisher / container
      data['venue'] = pub['container-title'] || pub['publisher']

      # Volume / issue / pages
      data['volume']    = pub['volume']
      data['issue']     = pub['issue']
      firstpage, lastpage = split_pages(pub['page'])
      data['firstpage'] = firstpage
      data['lastpage']  = lastpage

      # DOI, URL
      data['doi'] = pub['DOI']
      data['url'] = pub['URL']

      # Abstract & language
      data['abstract'] = pub['abstract']
      data['language'] = pub['language'] || 'en'

      # Category / extra
      cat, extra, book_title, editors = map_type_and_extras(pub)
      data['category']   = cat
      data['extra']      = extra if extra
      data['book_title'] = book_title if book_title
      data['editors']    = editors   if editors && !editors.empty?

      # PDF from Extra / note
      pdf_url = extract_pdf_url(pub['note'] || pub['extra'])
      data['pdf'] = pdf_url if pdf_url

      # Layout and standard front matter fields
      data['layout']          = 'default'  # your publication layout is "layout: default"
      data['collection']      = 'publications'
      data['author_profile']  = true
      data['share']           = true
      data['comments']        = true

      # Excerpt: use abstract as excerpt if present
      data['excerpt'] = pub['abstract'] if pub['abstract']

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
      cat  = 'other'
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
        cat   = 'books'
        extra = 'chapter'
        book_title = pub['container-title']
        if pub['editor']
          editors = pub['editor'].map { |e|
            [e['family'], e['given']].compact.join(', ')
          }
        end
      when 'thesis'
        cat   = 'books'
        extra = 'thesis'
      else
        cat = 'other'
      end

      [cat, extra, book_title, editors]
    end

    def extract_pdf_url(extra_field)
      return nil unless extra_field.is_a?(String)
      extra_field.each_line do |line|
        if line.strip.start_with?('PDF:')
          return line.sub('PDF:', '').strip
        end
      end
      nil
    end
  end
end
