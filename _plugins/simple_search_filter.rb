module Jekyll
  module CharFilter
    def filtersss(input)
      input.gsub! '\\',''
      input.gsub! /\t/, ''
      input.gsub! '"', ''
      input.gsub! '<', ''
      input.gsub! '>', ''
      input.gsub! '/', ''
      input.gsub! /\n/, ''
    end
  end
end

Liquid::Template.register_filter(Jekyll::CharFilter)

