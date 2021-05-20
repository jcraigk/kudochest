import $ from 'jquery'

$(document).ready(function() {
  $('#features-list li a').on('click', function() {
    $('#feature-title').html($(this).text())
    $('#feature-detail').html($(this).data('detail'))
    $('#feature-icon').removeClass().addClass('fa btn-icon').addClass($(this).data('icon'))
    $('#features-modal').addClass('is-active')
  })
})
