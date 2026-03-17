module DocumentationHelper
  def render_markdown(content)
    renderer = Redcarpet::Render::HTML.new(
      hard_wrap: true,
      fenced_code_blocks: true,
      tables: true,
      no_styles: false
    )
    markdown = Redcarpet::Markdown.new(renderer,
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true,
      highlight: true,
      no_intra_emphasis: true
    )
    markdown.render(content).html_safe
  end
end
