# frozen_string_literal: true
module ChartHelper
  def column_chart_with_labels(name:, data:, user:, id:)
    column_chart \
      [{ name:, data:, library: chartjs_library_options(user) }],
      id:
  end

  def chartjs_library_options(user)
    {
      datalabels: {
        color: user.theme.dark? ? '#cccccc' : '#000000',
        align: 'top',
        anchor: 'end'
      }
    }
  end
end
