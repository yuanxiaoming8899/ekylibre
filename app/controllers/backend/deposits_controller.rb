# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

module Backend
  class DepositsController < Backend::BaseController
    manage_restfully only: :destroy

    respond_to :pdf, :odt, :docx, :xml, :json, :html, :ods, :xlsx

    unroll

    def self.deposit_conditions(_options = {})
      code = search_conditions(incoming_payments: %i[bank_check_number number]) + "||=[]\n"
      code << "if params[:paid_at].present? && params[:paid_at].to_s != 'all'\n"
      code << " c[0] << ' AND #{IncomingPayment.table_name}.paid_at::DATE BETWEEN ? AND ?'\n"
      code << " if params[:paid_at].to_s == 'interval'\n"
      code << "   c << params[:paid_at_started_on]\n"
      code << "   c << params[:paid_at_stopped_on]\n"
      code << " else\n"
      code << "   interval = params[:paid_at].to_s.split('_')\n"
      code << "   c << interval.first\n"
      code << "   c << interval.second\n"
      code << " end\n"
      code << "end\n"
      code << "if params[:id].present?\n"
      code << "  c[0] += \" AND \#{IncomingPayment.table_name}.deposit_id = ?\"\n"
      code << "  c << params[:id]\n"
      code << "else\n"
      code << "  c[0] += \" AND \#{IncomingPayment.table_name}.mode_id = ?\"\n"
      code << "  c << params[:mode_id]\n"
      code << "  c[0] += \" AND \#{IncomingPayment.table_name}.deposit_id IS NULL\"\n"
      code << "end\n"
      code << "c\n"
      code.c
    end

    list(order: { created_at: :desc }) do |t|
      # t.action :show, url: {format: :pdf}, image: :print
      t.action :edit, unless: :locked?
      t.action :destroy, unless: :locked?
      t.column :number, url: true
      t.column :amount, currency: true, url: true
      t.column :payments_count
      t.column :cash, url: true
      t.column :responsible, url: true
      t.column :created_at
      t.column :description, hidden: true
      t.column :journal_entry, url: true
    end

    # Displays the main page with the list of deposits
    def index
      unless IncomingPayment.depositables.any?
        notify_now(:no_depositable_payments)
      end
    end

    list(:payments, model: :incoming_payments, conditions: { deposit_id: 'params[:id]'.c }, pagination: :none, order: :number) do |t|
      t.column :number, url: true
      t.column :payer, url: true
      t.column :bank_name
      t.column :bank_account_number
      t.column :bank_check_number
      t.column :paid_at
      t.column :amount, currency: true, url: true
    end

    # Displays details of one deposit selected with +params[:id]+
    def show
      return unless @deposit = find_and_check

      t3e @deposit
      respond_with(@deposit, include: [:responsible, :journal_entry, :mode, :cash,
                                       { payments: { include: :payer } }])
    end

    list(:depositable_payments, model: :incoming_payments, conditions: deposit_conditions, paginate: true, order: %i[to_bank_at created_at], line_class: "((resource.payments.exists?(RECORD.id) rescue false) ? 'success' : (RECORD.to_bank_at.to_date || Date.yesterday) > Time.zone.today ? 'critic' : '')".c) do |t|
      t.column :number, url: true
      t.column :payer, url: true
      t.column :bank_name
      t.column :bank_account_number
      t.column :bank_check_number
      t.column :paid_at
      t.column :responsible
      t.column :amount, currency: true
      t.check_box :to_deposit, value: '(resource.payments.exists?(RECORD.id) rescue false) || (RECORD.to_bank_at.to_date <= Time.zone.today && (params[:id].blank? ? (RECORD.responsible.nil? or RECORD.responsible_id == current_user.person_id) : (RECORD.deposit_id == params[:id])))'.c, label: :to_deposit.tl, form_name: 'deposit[payment_ids][]', form_value: 'RECORD.id'.c
    end

    def new
      return unless mode = find_mode

      @deposit = Deposit.new(
        created_at: Time.zone.today,
        mode: mode,
        cash: mode.cash,
        responsible: current_user.person
      )
      t3e mode: @deposit.mode.name
    end

    def create
      return unless find_mode

      payment_ids = permitted_params.delete('payment_ids')

      fye = find_fy_exchange(payment_ids)
      if fye.present?
        notify_error :financial_year_exchange_deposit.tn(code: fye)
        redirect_to(backend_deposits_path)
      else
        @deposit = Deposit.new(permitted_params)
        if @deposit.present?
          @deposit.save!
          notify_success(:deposit_in_preparation)
          DepositPaymentsJob.perform_later(id: @deposit.id, payment_ids: payment_ids, user_id: current_user.id)
          redirect_to(backend_deposits_path)
        else
          t3e mode: @deposit.mode.name
        end
      end
    end

    def edit
      return unless @deposit = find_and_check

      t3e @deposit
    end

    def update
      return unless @deposit = find_and_check
      return if save_and_redirect(@deposit, attributes: permitted_params, url: { action: :index })

      t3e @deposit
    end

    list(:unvalidateds, model: :deposits, conditions: { locked: false }) do |t|
      t.column :created_at
      t.column :amount
      t.column :payments_count
      t.column :cash, url: true
      t.check_box :validated, value: 'RECORD.created_at <= Time.zone.today-(15)'.c
    end

    def unvalidateds
      @deposits = Deposit.unvalidateds
      if request.post?
        # rubocop:disable Style/For
        for id, values in params[:unvalidateds] || {}
          return unless deposit = find_and_check(id: id)

          deposit.update_attributes!(locked: true) if deposit && values[:validated].to_i == 1
        end
        # rubocop:enable Style/For
        redirect_to action: :unvalidateds
      end
    end

    protected

      def find_mode(id = nil)
        unless mode = IncomingPaymentMode.find_by(id: id || params[:mode_id])
          notify_warning(:need_payment_mode_to_create_deposit)
          redirect_to action: :index
          return nil
        end
        if params[:deposit] && params[:deposit][:mode_id] && params[:deposit][:mode_id].to_i != mode.id
          notify_error(:need_payment_mode_to_create_deposit)
          redirect_to action: :index
          return nil
        end
        unless mode.depositable_payments.any?
          notify_warning(:no_payment_to_deposit)
          redirect_to action: :index
          return nil
        end
        mode
      end

      def find_fy_exchange(payment_ids)
        payment_ids.map do |p_id|
          fye = FinancialYearExchange.opened.at(IncomingPayment.find(p_id).paid_at)
          if fye.any?
            return fye.first.financial_year.code
          end
        end

        return false
      end
  end
end
