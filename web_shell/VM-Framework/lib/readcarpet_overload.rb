class Redcarpet::Render::ColorHTML < Redcarpet::Render::HTML
  attr_accessor :toc

  def render_menu
    result = <<-HTML
    <ul class="nav nav-list bs-docs-sidenav">
      HTML
      @toc.each_with_index do |item,index|
        if index == 0
          result << "<li class=\"active\"><a href=\"#toc_#{index + 1}\"><i class=\"icon-chevron-right\"></i> #{item}</a></li>"
        else
          result << "<li><a href=\"#toc_#{index + 1}\"><i class=\"icon-chevron-right\"></i> #{item}</a></li>"
        end
      end
      result << "</ul>"
    end

    def table(header, body)
      <<-HTML
      <table class='table table-striped table-bordered table-condensed'><thead>#{header}</thead>#{body}</table>
      HTML
    end

    def doc_footer()
      if @toc.length > 0
        <<-HTML
      </section>
      HTML
    end
  end

  def header(text, header_level)
    @toc = [] if @toc.nil?

    if header_level == 1
      @toc << text
      if @toc.length == 1
        <<-HTML
        <section id="toc_#{@toc.length}">
          <div class="page-header">
            <h1 >#{text}</h1>
          </div>
          HTML
      else
          <<-HTML
        </section>
        <section id="toc_#{@toc.length}">
          <div class="page-header">
            <h1 >#{text}</h1>
          </div>
          HTML
      end
    elsif header_level == 2
      <<-HTML
      <h2>#{text}</h2>
      HTML
    elsif header_level == 3
      <<-HTML
      <h3>#{text}</h3>
      HTML
    elsif header_level == 4
      <<-HTML
      <h4>#{text}</h4>
      HTML
    else
      <<-HTML
      <h5>#{text}</h5>
      HTML
    end

  end

  def block_code(code, language)
    options = { options: {encoding: 'utf-8'} }
#    options.merge!(lexer: language.downcase) if Pygments::Lexer.find(language)

    if language.nil?
      <<-HTML
      <pre><code>#{code}</code></pre>
      HTML
    else
      <<-HTML
      <pre><code class='#{language.downcase}'>#{code}</code></pre>
      HTML
    end
  end

end