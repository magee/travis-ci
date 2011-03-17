require 'uri'

class Repository < ActiveRecord::Base
  has_many :builds, :dependent => :delete_all, :conditions => 'parent_id IS null'
  has_one :last_build,          :class_name => 'Build', :order => 'started_at DESC', :conditions => 'parent_id IS null AND started_at IS NOT NULL'
  has_one :last_finished_build, :class_name => 'Build', :order => 'started_at DESC', :conditions => 'parent_id IS null AND finished_at IS NOT NULL'
  has_one :last_success,        :class_name => 'Build', :order => 'started_at DESC', :conditions => 'parent_id IS null AND status = 0'
  has_one :last_failure,        :class_name => 'Build', :order => 'started_at DESC', :conditions => 'parent_id IS null AND status = 1'

  REPOSITORY_ATTRS = [:id, :name]
  LAST_BUILD_ATTRS = [:last_build_id, :last_build_number, :last_build_status, :last_build_started_at, :last_build_finished_at]

  class << self
    def timeline
      where(arel_table[:last_build_started_at].not_eq(nil)).order(arel_table[:last_build_started_at].desc)
    end

    def recent
      limit(20)
    end

    def human_status_by_name(name)
      repository = find_by_name(name)
      return 'unknown' unless repository && repository.last_finished_build
      repository.last_finished_build.status == 0 ? 'stable' : 'unstable'
    end
  end

  before_create :init_names

  def as_json(options = nil)
    options ||= {} # ActiveSupport seems to pass nil here?
    options.reverse_merge!(:only => REPOSITORY_ATTRS)
    options[:only] += LAST_BUILD_ATTRS unless options[:for] == :build
    super(options)
  end


  protected

    def init_names
      self.name ||= URI.parse(url).path.split('/')[-2, 2].join('/')
      self.username = name.split('/').first
    end
end
