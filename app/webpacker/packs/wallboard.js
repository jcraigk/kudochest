import consumer from './consumer'

// (function() {
//   this.App || (this.App = {})
//
//   App.cable = ActionCable.createConsumer()
// }).call(this)

consumer.subscriptions.create(
  { channel: 'ResponseChannel' },
  {
    received(text) {
      // Hide placeholder, show container
      $('#placeholder').hide()
      $('#response_container').show()

      // Append new response and scroll to bottom
      $('#responses').append(`<p>${text}</p>`)
      $('#responses').scrollTop($('#responses').height())

      // Remove responses that have been scrolled past
      var total = $('#responses p').length
      $('#responses').find('p').slice(0, total - 30).remove()
    }
  }
)


$(function() {
  // Click button for fullscreen mode, click or keypress anywhere to exit
  $('#fullscreen-mode').on('click', function(e) {
    enterFullscreen()
    e.stopPropagation()
  })
  $(document).on('keyup', function() {
    exitFullscreen()
  })
  $('#main').on('click', function() {
    exitFullscreen()
  })

  function enterFullscreen() {
    $('#main').addClass('fullscreen-mode')
    $('#navbar').hide()
    $('#wallboard-options').hide()
    $('footer').hide()
  }

  function exitFullscreen() {
    $('#main').removeClass('fullscreen-mode')
    $('#navbar').show()
    $('#wallboard-options').show()
    $('footer').show()
  }

  // Periodically showcase a random profile
  setInterval(function() {
    fetchRandomShowcase()
  }, 30000);

  function fetchRandomShowcase() {
    $('#refresh-progress').addClass('transition2').val(0)
    var profile_id = $('#showcase_profile_id').data('id')
    $.get('/profiles/random_showcase?last_profile_id=' + profile_id, function(data) {
      $('#profile').html(data)
      $('#refresh-progress').removeClass('transition2').addClass('transition').val(100)
    });
  }

  fetchRandomShowcase()
})
