module JekyllAdmin
  class Server < Sinatra::Base
    include JekyllAdmin::PathHelper

    PRODUCTION_BRANCH = "marketing"
    DRAFT_BRANCH_PREFIX = "marketing-draft-"

    namespace "/version" do

      get "/list" do
        json(list_branches)
      end

      get "/create" do
        json({:name => create_branch})
      end

      get "/save" do
        json({:name => save_branch})
      end

      get "/load" do
        version = params[:version]
        json({:name => load_branch(version)})
      end

      get "/promote" do
        json({:name => promote_branch})
      end

      get "/delete" do
        json({:name => delete_branch})
      end

      private

      def open_repo
        begin
          Git.open(JekyllAdmin.site.source, :log => Jekyll.logger)
          #Git.open('~/Work/everlution/projects/roxhill-marketing', :log => Jekyll.logger)
        rescue ArgumentError
          Jekyll.logger.warn "Not a git repo: " + $!.message
          raise
        end
      end

      # 'List' all versions by filter branch list.
      def list_branches
        g = open_repo
        g.branches.local.select do |branch|
          branch.name.include? "marketing"
        end
      end

      # 'Create' a version by creating a draft branch off site prod branch.
      def create_branch
        new_branch_name = DRAFT_BRANCH_PREFIX + (Time.now.utc.to_i.to_s)
        g = open_repo
        g.branch(PRODUCTION_BRANCH).checkout
        g.branch(new_branch_name).create
        g.branch(new_branch_name).checkout
        #g.push
        g.current_branch
      end

      # 'Save' a version by adding all in current branch and commiting.
      def save_branch
        g = open_repo
        begin
          g.add(:all=>true)
          g.commit("Site updated by admin.")
          #g.push
        rescue Git::GitExecuteError
          Jekyll.logger.warn "No changes to save: " + $!.message
        end
        g.current_branch
      end

      # 'Load' a version by saving current branch and checking out another branch.
      def load_branch(branch_name)
        save_branch
        g = open_repo
        g.branch(branch_name).checkout
        g.current_branch
      end

      # 'Promote' a version by merging it into site prod branch.
      def promote_branch
        save_branch
        g = open_repo
        branch_name = g.current_branch
        g.branch(PRODUCTION_BRANCH).checkout
        g.merge(branch_name)
        #g.push
        g.current_branch
      end

      def delete_branch
        save_branch
        g = open_repo
        branch_name = g.current_branch
        g.branch(PRODUCTION_BRANCH).checkout
        g.branch('branch_name').delete
        #g.push
        g.current_branch
      end
    end
  end
end
