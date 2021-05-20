import $ from 'jquery'

$(document).ready(function() {
  // JS Demo
  var txt = ['@Lisa ++', '@Vincent ++2 great presentation!', '/karma top']
  var response_classes = ['response-lisa', 'response-vincent', 'response-top']
  var type_time = 100
  var response_time = 500
  var refresh_time = 5000
  var i = 0
  var idx = 0
  var $chat1 = $('#chat1-content')
  var $chat2 = $('#chat2-container')

  typeWriter()
  function typeWriter() {
    if (i < txt[idx].length) {
      $chat1.html($chat1.html() + txt[idx].charAt(i))
      highlightUsernames()
      i++
      setTimeout(typeWriter, type_time)
    } else {
      setTimeout(addResponse, response_time)
    }
  }

  function addResponse() {
    $chat2.removeClass('hidden')
    $('.' + response_classes[idx]).removeClass('hidden')
    setTimeout(next_frame, refresh_time)
  }

  function next_frame() {
    $chat2.addClass('hidden')
    $('.' + response_classes[idx]).addClass('hidden')
    $chat1.html('')
    i = 0
    idx++
    if (idx == txt.length) idx = 0
    typeWriter()
  }

  function highlightUsernames() {
    var highlighted = $chat1.html().replace(/(@[a-zA-Z0-1_-]+)\s/, "<span class='profile-ref'>$1</span> ")
    $chat1.html(highlighted)
  }


  // Features list
  $('#features-list li a').on('click', function() {
    $('#feature-title').html($(this).text())
    $('#feature-detail').html($(this).data('detail'))
    $('#feature-icon').removeClass().addClass('fa btn-icon').addClass($(this).data('icon'))
    $('#features-modal').addClass('is-active')
  })
})
