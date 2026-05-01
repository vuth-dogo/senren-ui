# frozen_string_literal: true

module Senren
  class InviteMemberDialogComponent < BaseComponent
    renders_one :trigger
    renders_one :footer

    VARIANTS = { default: '' }.freeze
    SIZES = { md: '' }.freeze

    def initialize(title: 'Invite teammate', description: 'Send an invitation to join this workspace.',
                   email_name: 'email', role_name: 'role', roles: %w[Member
                                                                     Admin], button_label: 'Invite member', id: nil, class_name: nil, **html)
      super(variant: :default, size: :md, class_name: class_name, **html)
      @title = title
      @description = description
      @email_name = email_name
      @role_name = role_name
      @roles = Array(roles)
      @button_label = button_label
      @dom_id = id || "senren-invite-member-#{SecureRandom.hex(3)}"
    end

    attr_reader :title, :description, :email_name, :role_name, :roles, :button_label, :dom_id
  end
end
