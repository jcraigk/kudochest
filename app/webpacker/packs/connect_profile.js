const ClipboardJS = require('clipboard')

$(document).ready(function() {
  new ClipboardJS('.clipboard-btn')
  $('.clipboard-btn').on('click', function() {
    $('#copy-icon').hide()
    $('#check-icon').show()
    setTimeout(function() {
      $('#copy-icon').show()
      $('#check-icon').hide()
    }, 2000)
  })
})
