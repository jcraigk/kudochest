require.context('../images', true);

import 'chart.js'
import 'chartkick'
import 'select2'
import $ from 'jquery'

require('@rails/ujs').start()

$(document).ready(function() {
  // Navbar burger menu
  $('.navbar-burger').on('click', function(e) {
    $('.navbar-burger').toggleClass('is-active')
    $('.navbar-menu').toggleClass('is-active')
  })

  // Dropdowns
  $('.dropdown-trigger').on('click', function(e) {
    $(this).parent().toggleClass('is-active')
    return false
  })
  $(document).on('click', function() {
    $('.dropdown').removeClass('is-active')
  })

  // Notifications
  $('.delete-notification').on('click', function() {
    $(this).parent().remove()
  })

  // Smooth scroll
  $('a[href*="#"]').on('click', function(e) {
    e.preventDefault()
    $('html, body').animate(
      { scrollTop: $($(this).attr('href')).offset().top - 150 },
      1000
    )
  })

  // Modals
  $('.modal-background').on('click', function() {
    $('.modal').removeClass('is-active')
  })

  // Select2
  $(function() {
    $('.select2').select2()
  })

  // Auto-submit controls
  $('.autosubmit').on('change', function() {
    $(this).closest('form').submit()
  })
})
