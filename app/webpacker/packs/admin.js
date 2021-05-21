import 'select-pure'

$(document).ready(function() {
  // TODO: Fix this for Exempt Users input
  // var event = new Event('select-pure-change')
  // var select_pure = new SelectPure('#profile-multi-select', {
  //   multiple: true,
  //   placeholder: false,
  //   autocomplete: true,
  //   icon: 'fa fa-times',
  //   options: #{{@team_profile_options.to_json}},
  //   value: #{{@infinite_profile_rids.to_json}},
  //   onChange: value => {
  //     this.dispatchEvent(event)
  //     $('#infinite_profile_rids').val(value.join(':'))
  //   }
  // })

  var dirty = false
  var submitted = false

  $(window).on('beforeunload', function(){
    if (dirty && !submitted) {
      return 'Are you sure you want to leave?';
    }
  });

  function updateButtons() {
    if (dirty) {
      $('#btn-save-changes').addClass('is-primary')
      $('#btn-discard-changes').addClass('is-danger')
    } else {
      $('#btn-save-changes').removeClass('is-primary')
      $('#btn-discard-changes').removeClass('is-danger')
    }
  }

  function dirtyForm() {
    dirty = true
    updateButtons()
  }

  function cleanForm() {
    dirty = false
    updateButtons()
  }

  $(function() {
    updateButtons()

    $('.card').hide()

    if ('#{session[:section]}' != '') {
      $("[data-section='#{session[:section]}']").show()
      $("[data-link='#{session[:section]}']").addClass('is-active')
    } else {
      $('.card:first').show()
      $('.team-setting-link:first').addClass('is-active')
    }

    $('.team-setting-link').on('click', function() {
      $('.card').hide()
      $('.team-setting-link').removeClass('is-active')
      $(this).addClass('is-active')
      var section_name = $(this).data('link')
      $('#section').attr('value', section_name)
      var section_selector = "[data-section='" + section_name  + "']"
      $(section_selector).show()
    })

    $(':input').on('change', function() {
      dirtyForm()
    })
    $(window).on('select-pure-change', function() {
      dirtyForm()
    })

    $('#btn-discard-changes').on('click', function() {
      cleanForm
    })
    $('#btn-save-changes').on('click', function() {
      submitted = true
    })
  })
})
