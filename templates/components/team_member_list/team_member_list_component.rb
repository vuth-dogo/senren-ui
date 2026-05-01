# frozen_string_literal: true

module Senren
  class TeamMemberListComponent < BaseComponent
    VARIANTS = { default: '' }.freeze
    SIZES = { md: '' }.freeze

    def initialize(members: [], class_name: nil, **html)
      super(variant: :default, size: :md, class_name: class_name, **html)
      @members = Array(members)
    end

    attr_reader :members

    def member_value(member, key)
      member.is_a?(Hash) ? (member[key] || member[key.to_s]) : nil
    end

    def initials_for(member)
      explicit = member_value(member, :initials)
      return explicit if explicit.present?

      member_value(member, :name).to_s.split.map { |part| part[0] }.join.first(2).upcase
    end
  end
end
