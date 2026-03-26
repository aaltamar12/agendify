# frozen_string_literal: true

Grover.configure do |config|
  config.options = {
    format: "A4",
    margin: {
      top: "20mm",
      bottom: "20mm",
      left: "15mm",
      right: "15mm"
    },
    print_background: true,
    prefer_css_page_size: true
  }
end
