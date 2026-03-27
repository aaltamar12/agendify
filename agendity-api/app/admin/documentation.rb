# frozen_string_literal: true

ActiveAdmin.register_page "Documentation" do
  menu parent: "Herramientas", priority: 2, label: "Documentación"

  content do
    renderer_html = Redcarpet::Render::HTML.new(
      hard_wrap: true,
      fenced_code_blocks: true,
      tables: true,
      no_styles: false
    )
    md = Redcarpet::Markdown.new(renderer_html,
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true,
      highlight: true,
      no_intra_emphasis: true
    )

    docs_base = Rails.root.join("..", "docs")
    tech_path = docs_base.join("tech")
    decisions_path = tech_path.join("decisiones")
    pricing_file = docs_base.join("pricing-detalle-planes.md")
    desarrollo_file = Rails.root.join("..", "desarrollo.md")

    # CSS
    div class: "documentation-wrapper" do
      text_node %(<style>
        .doc-content { max-width: 900px; padding: 20px; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; line-height: 1.6; }
        .doc-content h1 { font-size: 1.8em; border-bottom: 2px solid #7C3AED; padding-bottom: 8px; margin-top: 24px; }
        .doc-content h2 { font-size: 1.4em; border-bottom: 1px solid #E5E7EB; padding-bottom: 6px; margin-top: 20px; }
        .doc-content h3 { font-size: 1.2em; margin-top: 16px; }
        .doc-content table { border-collapse: collapse; width: 100%; margin: 12px 0; }
        .doc-content table th, .doc-content table td { border: 1px solid #D1D5DB; padding: 8px 12px; text-align: left; font-size: 0.9em; }
        .doc-content table th { background: #F3F4F6; font-weight: 600; }
        .doc-content code { background: #F3F4F6; padding: 2px 6px; border-radius: 4px; font-size: 0.9em; }
        .doc-content pre { background: #1F2937; color: #E5E7EB; padding: 16px; border-radius: 8px; overflow-x: auto; }
        .doc-content pre code { background: none; padding: 0; color: inherit; }
        .doc-content blockquote { border-left: 4px solid #7C3AED; margin: 12px 0; padding: 8px 16px; background: #F5F3FF; }
        .doc-content a { color: #7C3AED; }
        .doc-content hr { border: none; border-top: 1px solid #E5E7EB; margin: 24px 0; }
        .doc-content ul, .doc-content ol { padding-left: 24px; }
        .doc-content li { margin: 4px 0; }
      </style>).html_safe
    end

    # ONE tabs block for everything
    tabs do
      # Tech docs
      if File.directory?(tech_path)
        Dir.glob(tech_path.join("*.md")).sort.each do |file|
          filename = File.basename(file, ".md")
          label = filename.split("-").map(&:capitalize).join(" ")

          tab label do
            div class: "doc-content" do
              text_node md.render(File.read(file)).html_safe
            end
          end
        end
      end

      # ADRs — grouped under one tab
      if File.directory?(decisions_path)
        adr_files = Dir.glob(decisions_path.join("*.md")).sort

        tab "Decisiones Tecnicas (#{adr_files.size})" do
          tabs do
            adr_files.each do |file|
              filename = File.basename(file, ".md")
              tab filename do
                div class: "doc-content" do
                  text_node md.render(File.read(file)).html_safe
                end
              end
            end
          end
        end
      end

      # Pricing
      if File.exist?(pricing_file)
        tab "Pricing" do
          div class: "doc-content" do
            text_node md.render(File.read(pricing_file)).html_safe
          end
        end
      end

      # Onboarding / Testing Guide
      onboarding_file = docs_base.join("onboarding-testing-guide.md")
      if File.exist?(onboarding_file)
        tab "Onboarding & Testing" do
          div class: "doc-content" do
            text_node md.render(File.read(onboarding_file)).html_safe
          end
        end
      end

      # Desarrollo
      if File.exist?(desarrollo_file)
        tab "Plan de Desarrollo" do
          div class: "doc-content" do
            text_node md.render(File.read(desarrollo_file)).html_safe
          end
        end
      end
    end

    # Mermaid CDN
    text_node %(<script type="module">
      import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs';
      mermaid.initialize({ startOnLoad: false, theme: 'default' });
      document.querySelectorAll('.doc-content pre code').forEach(function(el) {
        var text = el.textContent;
        if (text.match(/^(graph|flowchart|sequenceDiagram|stateDiagram|classDiagram|erDiagram)/)) {
          var div = document.createElement('div');
          div.className = 'mermaid';
          div.textContent = text;
          el.closest('pre').replaceWith(div);
        }
      });
      mermaid.run();
    </script>).html_safe
  end
end
