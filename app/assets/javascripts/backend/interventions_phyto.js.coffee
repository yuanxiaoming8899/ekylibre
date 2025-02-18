((E, $) ->
  retrieveTargetsData = () =>
    $('[data-phytosanitary-target]').toArray()
      .filter((el) => !el.classList.contains('removed-nested-fields'))
      .map (element) =>
        shape_value = $(element).find('.intervention_targets_working_zone input').val() || $(element).find('.intervention_group_parameters_targets_working_zone input').val()
        working_zone_area_value = $(element).find('.intervention_targets_working_zone_area input').val() || $(element).find('.intervention_group_parameters_targets_working_zone_area input').val()
        id: $(element).find("[data-selector-id='intervention_target_product_id']").next('.selector-value').val()
        shape: shape_value
        working_zone_area_value: working_zone_area_value

  retrieveMaxStoppedAt = () =>
    stoppedAtDates = $(".intervention-stopped-at[type='hidden']").map ->
      if $(this).val() then new Date($(this).val()) else null

    moment(_.max(_.compact(stoppedAtDates)))

  productsInfos =
    display: () ->
      that = this
      $('.nested-plant_medicine').each -> that._clear($(this))
      values = @._retrieveValues()

      $.ajax(url: '/backend/registered_phytosanitary_products/get_products_infos',dataType: "json", data: values, method: 'POST')
       .done( (data) =>
          for id, infos of data
            $productField = $(".selector-value[value='#{id}']").closest('.nested-plant_medicine')

            @._displayAllowedMentions($productField, infos.allowed_mentions)
            @._displayBadge($productField, infos.state, infos.check_conditions)
            @._displayMessages($productField, infos.messages)
        )

    _displayAllowedMentions: ($productField, allowedMentions) ->
      $productField.find('span.allowed-mentions').insertAfter($productField.find('.intervention_inputs_product .selector'))
      for mention in allowedMentions
        $productField.find("##{mention}").show()

    _displayBadge: ($productField, state, checkConditions) ->
      new StateBadgeSet($productField.find('#intervention-products-badges')).setState(state)
      $productField.find('.input-authorization__text').show() if checkConditions

    _displayMessages: ($productField, messages) ->
      for key, value of messages
        if key == 'usage'
          htmlString = '<span id="usage-authorization-message"></span>'
          $productField.find('.intervention_inputs_usage .controls .lights-message').html(htmlString)
        $productField.find("##{key}-authorization-message").html(messages[key].join('<br>'))

    _clear: ($productField) ->
      $productField.find('.allowed-mentions img').each -> $(this).hide()
      new StateBadgeSet($productField.find('#intervention-products-badges')).setState(null)
      $productField.find('.input-authorization__text').hide()
      $productField.find('#product-authorization-message').html('')

    _retrieveValues: () ->
      targetsData = retrieveTargetsData()

      productsData = Array.from(document.querySelectorAll(".nested-plant_medicine"))
        .filter((el) => !el.classList.contains('removed-nested-fields'))
        .map (element) =>
          product_id: element.querySelector('.intervention_inputs_product input.selector-value').value
          usage_id: element.querySelector('.intervention_inputs_usage input.selector-value').value
          quantity: element.querySelector('.intervention_inputs_quantity input').value
          unit_name: element.querySelector('.intervention_inputs_quantity select').selectedOptions[0].dataset.handlerUnit
          input_id: element.querySelector('#intervention_parameter_id').value
          live_data: element.querySelector('.intervention_inputs_using_live_data input').value

      interventionId = $('input#intervention_id').val()

      startedAtDates = $(".intervention-started-at[type='hidden']").map ->
        if $(this).val() then new Date($(this).val()) else null

      minStartedAt = _.min(_.compact(startedAtDates))

      {
        products_data: _.reject(productsData, (data) -> data.product_id == '' ),
        targets_data: _.reject(targetsData, (data) -> data.id == '' ),
        intervention_id: interventionId,
        intervention_started_at: moment(minStartedAt).format()
        intervention_stopped_at: retrieveMaxStoppedAt().format()
      }


  usageMainInfos =
    display: ($input, $productField) ->
      @._clear($productField)
      $productField.find("input[data-intervention-field='quantity-value']").trigger('input')
      usageId = $input.next('.selector-value').val()
      return unless usageId
      values = @._retrieveValues($productField)

      $.ajax(url: "/backend/registered_phytosanitary_usages/#{usageId}/get_usage_infos", dataType: "json", data: values, method: 'POST')
        .done( (data) =>
          @._displayInfos($productField, data.usage_infos)
          @._displayApplication($input, data.usage_application)
          @.displayAuthorizationDisclaimer($productField, data.modified)
          sprayingMap.refresh()
        )

    displayAuthorizationDisclaimer: ($productField, modified) ->
      if modified
        $('.authorization-disclaimer--past').hide()
        $('.authorization-disclaimer--present').show()
        $productField.find('.intervention_inputs_using_live_data input').val(true)

    _displayInfos: ($productField, infos) ->
      for key, value of infos
        if key == "usage_conditions" && value != null
          value = value.replace(/\n/, '<br />')

        $productField.find("[data-usage-attribute='#{key}']").html(value || '-')

      $productField.find('.usage-infos-container').show()

    _displayApplication: ($input, application) ->
      for key, value of application
        addedClass = if key == 'stop' then 'warning' else ''
        $input.closest('.controls').find('.lights').addClass("lights-#{key}")
        $input.closest('.controls').find('.lights-message').addClass(addedClass).text("#{value}")

    _clear: ($productField) ->
      $productField.find('.lights').removeClass('lights-go lights-caution lights-stop')
      $productField.find('.lights-message').removeClass('warning').text('')
      $productField.find('#product-authorization-message').text('')
      $productField.find('.usage-infos-container').hide()

    _retrieveValues: ($productField) ->
      interventionId = $('input#intervention_id').val()
      inputId = $productField.find('#intervention_parameter_id').val()
      productId = $productField.find("[data-selector-id='intervention_input_product_id']").first().selector('value')
      liveData = $productField.find('.intervention_inputs_using_live_data input').val()
      $plantInputs = $('.nested-cultivation').filter -> $(this).find("[data-selector-id='intervention_target_product_id']").first().selector('value')
      targetsData = retrieveTargetsData()
      stopped_at = retrieveMaxStoppedAt().format()

      { product_id: productId, targets_data: targetsData, intervention_id: interventionId, input_id: inputId, live_data: liveData, intervention_stopped_at: stopped_at }


  usageDoseInfos =
    displayAll: () ->
      that = this
      $('.nested-plant_medicine').each -> 
        that.display($(this).find("input[data-intervention-field='quantity-value']"), $(this))

    display: ($quantityInput, $productField) ->
      @._clearLights($quantityInput)
      usageId = $productField.find("[data-selector-id='intervention_input_usage_id']").next('.selector-value').val()
      return unless usageId
      values = @._retrieveValues($quantityInput, $productField)
      return unless values.product_id && values.quantity && values.unit_name && values.targets_data

      $.ajax(url: "/backend/registered_phytosanitary_usages/#{usageId}/dose_validations", dataType: "json", data: values, method: 'POST')
        .done( (data) =>
          @._displayDose($quantityInput, data)
          usageMainInfos.displayAuthorizationDisclaimer($productField, data.modified)
        )

    _displayDose: ($input, data) ->
      for key, value of data.dose_validation
        addedClass = if key == 'stop' then 'warning' else ''
        $input.closest('.nested-inputs').find('.intervention_inputs_quantity .lights').addClass("lights-#{key}")
        $input.closest('.nested-inputs').find('.intervention_inputs_quantity .lights-message').addClass(addedClass).text("#{value}")

    _clearLights: ($input) ->
      $input.closest('.nested-inputs').find('.intervention_inputs_quantity .lights').removeClass("lights-go lights-caution lights-stop")
      $input.closest('.nested-inputs').find('.intervention_inputs_quantity .lights-message').removeClass("warning")

    _retrieveValues: ($input, $productField) ->
      interventionId = $('input#intervention_id').val()
      inputId = $productField.find('#intervention_parameter_id').val()
      productId = $productField.find("[data-selector-id='intervention_input_product_id']").first().selector('value')
      liveData = $productField.find('.intervention_inputs_using_live_data input').val()
      quantity = $productField.find('.intervention_inputs_quantity input').val()
      unitName = $productField.find('.intervention_inputs_quantity select').get(0).selectedOptions[0].dataset.handlerUnit
      targetsData = retrieveTargetsData()
      sprayVolume = $productField.find("[data-intervention-field='spray-volume']").first().val()

      {
        product_id: productId,
        quantity: quantity,
        unit_name: unitName,
        targets_data: targetsData,
        intervention_id: interventionId,
        input_id: inputId,
        live_data: liveData
        spray_volume: sprayVolume
      }


  sprayingMap =
    refresh: ->
      value = @_retrieveValue()
      usagesIds = $("[data-selector-id='intervention_input_usage_id']").map -> $(this).selector('value')

      $('[data-map-editor]').each ->
        if value && !!usagesIds.length
          $(this).mapeditor 'displayOptionalOverlay', "aquatic_nta_#{value}"
        else if !value && !!usagesIds.length
          $(this).mapeditor 'hideOptionalOverlays'
        else
          defaultOverlay = $(this).data('map-editor').default_optional_data
          $(this).mapeditor 'displayOptionalOverlay', defaultOverlay if defaultOverlay

    _retrieveValue: ->
      values = $("[data-usage-attribute='untreated_buffer_aquatic']").map -> parseFloat($(this).text())
      values = _.reject(values, (val) -> isNaN val)
      if _.isEmpty(values) then null else Math.max(values)

  productListManager =
    retrieveProductsIds: ->
      Array.from(document.querySelectorAll(".nested-plant_medicine"))
          .filter((el) => !el.classList.contains('removed-nested-fields'))
          .map (element) =>
            productInputelement = element.querySelector('.intervention_inputs_product input.selector-value')

            if productInputelement
              productInputelement.value

    filterProducts: ->
      productsIds = productListManager.retrieveProductsIds()
      $productSelectors = $('[data-selector-id="intervention_input_product_id"]')
      $productSelectors.each -> productListManager.filterProduct($(this), productsIds)

    filterProduct: ($productSelector, productsIds) ->
      is_input = $productSelector.data('selectorId') == 'intervention_input_product_id'
      data_selector =  if is_input then $productSelector.attr('data-selector') else $productSelector.data('selector')
      url = new URL(window.location.origin.concat(data_selector))
      selectorId = $productSelector.next('.selector-value').val()
      url.searchParams.set('scope[excluding]', _.reject(productsIds, (n) -> n == selectorId ))
      dataSelectorUrl = url.pathname.concat(url.search)
      $productSelector.data('selector', dataSelectorUrl)
      $productSelector.attr('data-selector', dataSelectorUrl)

  sprayVolume = {
    selectors: {
      primaryInput: ".master-spray-volume input[id$='measure_value_value']",
      replicaInput: "[data-intervention-field='spray-volume']",
    }

    bindEvents: () ->
      $(document).on 'input', @selectors.primaryInput, ->
        $replicaInputs = $(sprayVolume.selectors.replicaInput)
        sprayVolume._updateReplicaInputs($replicaInputs, this.value)
      
      $(document).on 'cocoon:after-insert', '.nested-inputs', (_e, $insertedItem) ->
        $replicaInput = $insertedItem.find(sprayVolume.selectors.replicaInput)
        value = $(sprayVolume.selectors.replicaInput)
          .toArray()
          .filter( (e) -> e.value != '' )
          .map( (e) -> e.value )[0]
        sprayVolume._updateReplicaInputs($replicaInput, value || '', false)

    _updateReplicaInputs: (replicaInputs, value, trigger = true ) ->
      replicaInputs.each () ->
        $(this).val(value)
        $(this).trigger('change') if trigger
  }

  sprayVolume.bindEvents()

  # Update products infos on target remove
  $(document).on 'cocoon:after-remove', '.nested-targets', ->
    $("[data-selector-id='intervention_input_product_id']").trigger('selector:change')

  $(document).on 'cocoon:after-remove', '.nested-inputs', ->
    $("[data-selector-id='intervention_input_product_id']").trigger('selector:change')
    productListManager.filterProducts()
    sprayingMap.refresh()

  $(document).on 'selector:created', ".nested-plant_medicine [data-selector-id='intervention_input_product_id']", ->
    productListManager.filterProduct($(this), productListManager.retrieveProductsIds())

  # Re-trigger all filters on target change
  $(document).on 'selector:change', "[data-selector-id='intervention_target_product_id']", ->
    $("[data-selector-id='intervention_input_product_id']").trigger('selector:change')

  $(document).on 'selector:change', "[data-selector-id='intervention_input_usage_id']", ->
    productsInfos.display()
    usageMainInfos.display($(this), $(this).closest('.nested-plant_medicine'))

  # Refresh usages, allowed mentions and badges on product update
  $(document).on 'selector:change', "input[data-selector-id='intervention_input_product_id']", ->
    productsInfos.display()
    $usageInput = $(this).closest('.nested-plant_medicine').find("[data-selector-id='intervention_input_usage_id']").first()
    if $(this).val() != ''
      $usageInput.attr('disabled', false)

  $(document).on 'selector:change', "input[data-selector-id='intervention_input_product_id']", ->
    productListManager.filterProducts()

  # Update allowed doses on quantity change
  # And compute authorization badge again
  $(document).on 'input change', "input[data-intervention-field='quantity-value']", ->
    productsInfos.display()
    usageDoseInfos.display($(this), $(this).closest('.nested-plant_medicine'))

  $(document).on 'input change', "input[data-intervention-field='spray-volume']", ->
    productsInfos.display()
    $nestedPlantMedicine = $(this).closest('.nested-plant_medicine')
    usageDoseInfos.display($nestedPlantMedicine.find("input[data-intervention-field='quantity-value']"), $nestedPlantMedicine)
  
  $(document).on 'input change', "input[data-intervention-field='working-zone-area-value']", ->
    productsInfos.display()
    usageDoseInfos.displayAll()

  $(document).on 'selector:clear', "[data-selector-id='intervention_input_usage_id']", ->
    $('.nested-plant_medicine').each -> usageMainInfos.displayAuthorizationDisclaimer($(this), true)
    sprayingMap.refresh()

  $(document).on 'change intervention-field:value-updated', ".nested-fields.working-period input[type='hidden']", ->
    productsInfos.display()

  $(document).on 'cocoon:after-remove', '.nested-working_periods', ->
    productsInfos.display()

  $(document).on 'mapeditor:optional_data_loaded', '[data-map-editor]', ->
    sprayingMap.refresh()

  $(document).on 'mapchange', '[data-map-editor]', ->
    productsInfos.display()

) ekylibre, jQuery
