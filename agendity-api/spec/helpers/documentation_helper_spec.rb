# frozen_string_literal: true

require "rails_helper"

RSpec.describe DocumentationHelper do
  include described_class

  describe "#render_markdown" do
    it "renders markdown content as HTML" do
      html = render_markdown("# Hello\n\nThis is **bold** text.")
      expect(html).to include("<h1>Hello</h1>")
      expect(html).to include("<strong>bold</strong>")
    end

    it "renders fenced code blocks" do
      html = render_markdown("```ruby\nputs 'hello'\n```")
      expect(html).to include("<code")
    end

    it "renders tables" do
      md = "| Col1 | Col2 |\n|------|------|\n| A | B |"
      html = render_markdown(md)
      expect(html).to include("<table>")
    end
  end
end
