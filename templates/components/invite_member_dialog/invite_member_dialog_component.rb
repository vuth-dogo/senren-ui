# frozen_string_literal: true

module Senren
  class InviteMemberDialogComponent < BaseComponent
    renders_one :trigger
    renders_one :footer

    VARIANTS = { default: '' }.freeze
    SIZES = { md: '' }.freeze

    # The role option values stay `Member` and `Admin`, because that is what the
    # form submits and what the host's code compares against. Only the label a
    # person reads is translated.
    def initialize(title: senren_t('invite_member_dialog.title', default: 'Invite teammate'),
                   description: senren_t('invite_member_dialog.description',
                                         default: 'Send an invitation to join this workspace.'),
                   email_name: 'email', role_name: 'role',
                   roles: [['Member', senren_t('invite_member_dialog.role_member', default: 'Member')],
                           ['Admin', senren_t('invite_member_dialog.role_admin', default: 'Admin')]],
                   button_label: senren_t('invite_member_dialog.button', default: 'Invite member'),
                   id: nil, class_name: nil, **html)
      super(variant: :default, size: :md, class_name: class_name, **html)
      @title = title
      @description = description
      @email_name = email_name
      @role_name = role_name
      @roles = Array(roles)
      @button_label = button_label
      @dom_id = id || senren_dom_id(title)
    end

    attr_reader :title, :description, :email_name, :role_name, :roles, :button_label, :dom_id
  end
end
