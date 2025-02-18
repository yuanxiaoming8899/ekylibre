module Backend
  class IntegrationsController < Backend::BaseController
    manage_restfully only: []

    def index
      @integration_types = ActionIntegration::Base.descendants.sort_by(&:name)
      respond_to do |format|
        format.html
        format.xml  { render xml:  resource_model.all }
        format.json { render json: resource_model.all }
      end
    end

    def new
      unless params[:nature]
        head :unprocessable_entity
        return
      end
      if existing = Integration.find_by(nature: params[:nature])
        redirect_to action: :edit, controller: :integrations, id: existing.id
        return
      end
      @integration = Integration.new(nature: params[:nature], parameters: (params[:parameters] || {}))
      t3e(@integration.attributes.merge(name: @integration.name))
      render(locals: { cancel_url: :back })
    end

    def edit
      return unless @integration = find_and_check(:integration)

      if FinancialYearExchange.opened.present? && @integration.nature == "baqio"
        notify_warning(:financial_year_exchange_open_baqio_integration.tl)
      end

      t3e(@integration.attributes.merge(name: @integration.name))
      render(locals: { cancel_url: :back })
    end

    def destroy
      return unless existing = Integration.find_by(nature: params[:nature]) || Integration.find_by(nature: params[:id])

      redirect_to action: :index, controller: :integrations if existing.destroy!
    end

    def create
      @integration = resource_model.new(permitted_params)
      t3e(@integration.attributes.merge(name: @integration.name))
      return if save_and_redirect(@integration, url: backend_integrations_path)

      @integration.errors.full_messages.each do |message|
        notify_error message
      end
      render(locals: { cancel_url: backend_integrations_path })
    end

    def update
      return unless @integration = find_and_check(:integration)

      t3e(@integration.attributes.merge(name: @integration.name))
      @integration.attributes = permitted_params
      redirect_url = params[:redirect] ||= backend_integrations_path
      return if save_and_redirect(@integration, url: redirect_url)

      @integration.errors.full_messages.each do |message|
        notify_error message
      end
      render(locals: { cancel_url: :back })
    end

    def check
      unless params[:nature]
        head :unprocessable_entity
        return
      end
      @integration = Integration.find_or_initialize_by(nature: params[:nature])
      @integration.parameters[:access_token] = params[:access_token]
      @integration.parameters[:token_type] = params[:token_type] if params[:token_type]
      @integration.save!
      redirect_to action: :index
    end
  end
end
