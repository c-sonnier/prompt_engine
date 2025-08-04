module PromptEngine
  class WorkflowRunsController < ApplicationController
    layout "prompt_engine/admin"
    before_action :set_workflow
    before_action :set_workflow_run, only: [:show]
    
    def index
      @workflow_runs = @workflow.workflow_runs.recent.limit(50)
    end
    
    def show
      # @workflow_run already set by before_action
    end
    
    private
    
    def set_workflow
      @workflow = Workflow.find(params[:workflow_id])
    end
    
    def set_workflow_run
      @workflow_run = @workflow.workflow_runs.find(params[:id])
    end
  end
end
