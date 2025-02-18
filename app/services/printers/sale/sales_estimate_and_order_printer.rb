# frozen_string_literal: true

using Ekylibre::Utils::NumericLocalization

module Printers
  module Sale
    class SalesEstimateAndOrderPrinter < SalePrinterBase
      # Hack for displaying or not dynamic sections
      WITH_SIGNATURE = WITH_PARCELS = WITH_CONDITIONS = [{}].freeze
      WITHOUT_SIGNATURE = WITHOUT_PARCELS = IN_PROGRESS = WITHOUT_CONDITIONS = [].freeze

      def generate(r)
        # In progress or not
        state = sale.aborted? ? [{ aborted: :export_sales_aborted }] : IN_PROGRESS

        # Companies
        company = EntityDecorator.decorate(Entity.of_company)
        receiver = EntityDecorator.decorate(sale.client)

        # Cash
        cash = get_company_cash

        description = Maybe(sale).description.fmap { |d| [{ description: d }] }.or_else([])

        # Header
        r.add_image :company_logo, company.picture.path, keep_ratio: true if company.has_picture?

        # Title
        r.add_field :title, title
        r.add_field :expired_at, sale.expired_at&.to_date&.l

        # Aborted
        r.add_section('section-aborted', state) do |s|
          s.add_field(:aborted) { |item| item[:aborted].tl }
        end

        # Expired_at
        r.add_section('section-conditions', general_conditions) do |s|
          s.add_field(:expired_at) { sale.expired_at.to_date.l }
        end

        r.add_section('section-description', description) do |sd|
          sd.add_field(:description) { |item| item[:description] }
        end

        # Company_address
        r.add_field :company_name, company.full_name
        r.add_field :company_address, company.address
        r.add_field :company_email, company.email
        r.add_field :company_phone, company.phone
        r.add_field :company_website, company.website

        # Receiver_address
        r.add_field :receiver, receiver.full_name
        r.add_field :receiver_address, receiver.address
        r.add_field :receiver_phone, receiver.phone
        r.add_field :receiver_email, receiver.email

        # Estimate_number
        r.add_field :initial_number, sale.number

        # Items_table
        r.add_table('items', sale.items) do |t|
          t.add_field(:code) { |item| item.variant.number }
          t.add_field(:variant) { |item| "#{item.variant.name} (#{item.conditioning_unit.name})" }
          t.add_field(:annotation, &:annotation)
          t.add_field(:quantity) { |item| item.conditioning_quantity.round_l }
          t.add_field(:unit_pretax_amount) { |item| item.unit_pretax_amount.round_l_auto }
          t.add_field(:discount) { |item| item.reduction_percentage.round_l || '0.00' }
          t.add_field(:pretax_amount) { |item| item.pretax_amount.round_l }
          t.add_field(:vat_amount) { |item| (item.pretax_amount * item.tax.amount / 100).abs.round_l }
          t.add_field(:vat_rate) { |item| item.tax.amount.round_l }
          t.add_field(:amount) { |item| item.amount.round_l }
        end

        # vat totals
        r.add_table('vat-totals', build_vat_totals, headers: true) do |v|
          v.add_field(:vat_name) { |item| item[:tax_name] }
          v.add_field(:vat_rate) { |item| item[:tax_rate] }
          v.add_field(:vat_base) { |item| item[:tax_base_pretax_amount] }
          v.add_field(:vat_amount) { |item| item[:tax_amount] }
        end

        # Totals
        r.add_field :total_pretax, sale.pretax_amount.round_l
        r.add_field :total_vat, (sale.amount - sale.pretax_amount).round_l
        r.add_field :total, sale.amount.round_l

        if should_display_affair
          # Details
          r.add_table('details', sale.other_deals) do |s|
            s.add_field(:payment_date) { |item| AffairableDecorator.decorate(item).payment_date.l(format: '%d %B %Y') }
            s.add_field(:payment_mode) { |item| (item.is_a?(IncomingPayment) ? item.mode.name : '') }
            s.add_field(:payment_number, &:number)
            s.add_field(:payment_amount) { |item| item.class == sale.class ? '' : item.amount.round_l }
            s.add_field(:sale_affair) { |item| item.class == sale.class ? item.amount.round_l : '' }
          end

          # Affair + left to pay or receive
          r.add_field :affair_number, sale.affair.number
          if (sale.affair.debit - sale.affair.credit).negative?
            r.add_field :action, I18n.t('labels.receive').downcase
          else
            r.add_field :action, I18n.t('labels.pay').downcase
          end
          r.add_field :left_to_pay, (sale.affair.debit - sale.affair.credit).round_l
        end

        # Signature
        r.add_section('Section-signature', signatures) do |signature|
          signature
        end

        # Parcels
        r.add_section('Section-parcels', parcels) do |s|
          s.add_table('parcels', :parcel_items) do |t|
            t.add_field(:parcel_code) { |item| item.variant.number }
            t.add_field(:parcel_variant) { |item| item.variant.name }
            t.add_field(:parcel_quantity) { |item| item.quantity.round_l }
            t.add_field(:parcel_number) { |item| item.parcel.number }
            t.add_field(:planned_at) { |item| item.parcel.planned_at.l(format: '%d %B %Y') }
          end
        end

        # Date
        r.add_field :date, Time.zone.now.l(format: '%d %B %Y')

        # Footer
        r.add_field :footer, "#{I18n.t 'attributes.intracommunity_vat'} : #{company.vat_number} - #{I18n.t 'attributes.siret'} : #{company.siret_number} - #{I18n.t 'attributes.activity_code'} : #{company.activity_code}"

        # Bank details
        r.add_field :account_holder_name, cash.bank_account_holder_name.recover { company.bank_account_holder_name }.or_else('')
        r.add_field :bank_name, cash.bank_name.or_else('')
        r.add_field :bank_identifier_code, cash.bank_identifier_code.or_else('')
        r.add_field :iban, cash.iban.scan(/.{1,4}/).join(' ').or_else('')
      end

      def should_display_affair
        false
      end
    end
  end
end
