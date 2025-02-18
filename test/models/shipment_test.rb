# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2023 Ekylibre SAS
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
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: parcels
#
#  accounted_at                         :datetime
#  address_id                           :integer(4)
#  contract_id                          :integer(4)
#  created_at                           :datetime         not null
#  creator_id                           :integer(4)
#  currency                             :string
#  custom_fields                        :jsonb
#  delivery_id                          :integer(4)
#  delivery_mode                        :string
#  given_at                             :datetime
#  id                                   :integer(4)       not null, primary key
#  in_preparation_at                    :datetime
#  intervention_id                      :integer(4)
#  journal_entry_id                     :integer(4)
#  late_delivery                        :boolean
#  lock_version                         :integer(4)       default(0), not null
#  nature                               :string           not null
#  number                               :string           not null
#  ordered_at                           :datetime
#  planned_at                           :datetime         not null
#  position                             :integer(4)
#  prepared_at                          :datetime
#  pretax_amount                        :decimal(19, 4)   default(0.0), not null
#  purchase_id                          :integer(4)
#  recipient_id                         :integer(4)
#  reconciliation_state                 :string
#  reference_number                     :string
#  remain_owner                         :boolean          default(FALSE), not null
#  responsible_id                       :integer(4)
#  sale_id                              :integer(4)
#  sale_nature_id                       :integer(4)
#  sender_id                            :integer(4)
#  separated_stock                      :boolean
#  state                                :string           not null
#  storage_id                           :integer(4)
#  transporter_id                       :integer(4)
#  type                                 :string
#  undelivered_invoice_journal_entry_id :integer(4)
#  updated_at                           :datetime         not null
#  updater_id                           :integer(4)
#  with_delivery                        :boolean          default(FALSE), not null
#
require 'test_helper'

class ShipmentTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  setup do
    @variant = ProductNatureVariant.import_from_nomenclature(:carrot)
    @recipient = Entity.create!(last_name: 'Shipment test')
    @entity = Entity.create!(last_name: 'Parcel test')
    @product = @variant.products.create!(initial_population: 30)
    @address = @recipient.addresses.create!(canal: 'mail', mail_line_1: 'Yolo', mail_line_2: 'Another test')

    Preference.set!('permanent_stock_inventory', true)
  end

  test 'shipments' do
    to_send = [{
      conditioning_quantity: @product.population,
      source_product: @product,
      conditioning_unit: @product.variant.guess_conditioning[:unit]
    }]

    shipment = new_shipment(items_attributes: to_send)
    shipment.give!

    assert_equal 0, @product.population
  end

  # bookkeep on shipments
  test 'bookeep shipments' do
    to_send = [{
      conditioning_quantity: @product.population,
      source_product: @product,
      unit_pretax_stock_amount: 15,
      conditioning_unit: @product.variant.guess_conditioning[:unit]
    }]

    shipment = new_shipment(items_attributes: to_send)
    shipment.give!

    a_ids = shipment.journal_entry.items.pluck(:account_id)

    sm = Account.where(id: a_ids).where("number LIKE '6%'").first
    sm ||= Account.where(id: a_ids).where("number LIKE '7%'").first
    jei_sm = shipment.journal_entry.items.where(account_id: sm.id).first

    s = Account.where(id: a_ids).where("number LIKE '3%'").first
    jei_s = shipment.journal_entry.items.where(account_id: s.id).first

    # must have 0 on credit to SM ACCOUNT (6%)
    assert_equal 0, jei_sm.credit.to_i
    assert_equal 0, jei_sm.real_credit.to_i
    # must have GTZ on debit to SM ACCOUNT (6%)
    assert_operator 0, :<, jei_sm.debit.to_i
    assert_operator 0, :<, jei_sm.real_debit.to_i

    # must have 0 on débit to S ACCOUNT (3%)
    assert_equal 0, jei_s.debit.to_i
    assert_equal 0, jei_s.real_debit.to_i
    # must have GTZ on credit to S ACCOUNT (3%)
    assert_operator 0, :<, jei_s.credit.to_i
    assert_operator 0, :<, jei_s.real_credit.to_i
  end

  test 'ship giving a transporter' do
    new_shipment
    assert_nothing_raised { Shipment.ship(Shipment.where.not(state: :given), transporter_id: @entity.id) }
  end

  test 'ship without transporter' do
    new_shipment
    assert_raise { Shipment.ship(Shipment.where.not(state: :given)) }
  end

  # ???? TODO: Figure what that test was supposed to be
  test 'prevent empty items' do
    item = parcel_items(:shipment_items_001).attributes.slice('product_id', 'population', 'shape')
    Shipment.new items_attributes: { '123456789' => { 'product_id' => '', '_destroy' => 'false' }, '852' => item }
    # parcel.items.map(&:net_mass)
  end

  private

    def new_shipment(delivery_mode: :third, address: nil, recipient: nil, separated: true, items_attributes: nil)
      attributes = {
        delivery_mode: delivery_mode,
        recipient: recipient || @recipient,
        address: address || @address,
        separated_stock: separated,
        given_at: DateTime.new(2018, 1, 1)
      }

      items_attributes ||= [{
        conditioning_quantity: 20,
        source_product: @product,
        unit_pretax_stock_amount: 15,
        variant: @variant,
        conditioning_unit: @variant.guess_conditioning[:unit]
      }]

      shipment = Shipment.create!(attributes)
      items_attributes.each do
        shipment.items.create!(items_attributes)
      end

      shipment
    end
end
