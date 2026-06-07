# frozen_string_literal: true

# Bootstrap Form configuration for MDB UI Kit compatibility
BootstrapForm.configure do |c|
  # Use MDB-specific dismiss attribute instead of Bootstrap's data-bs-dismiss
  # rubocop:disable Style/FormatStringToken
  c.alert_message = <<~HTML.html_safe
    <div class="alert alert-danger alert-dismissible fade show" role="alert">
      <button type="button" class="btn-close" data-mdb-dismiss="alert" aria-label="Close"></button>
      <p class="mb-0">%{text}</p>
      %{list}
    </div>
  HTML
  # rubocop:enable Style/FormatStringToken
end
