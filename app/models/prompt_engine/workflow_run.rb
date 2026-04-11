module PromptEngine
  class WorkflowRun < ApplicationRecord
    belongs_to :workflow
    
    validates :status, presence: true
    validates :execution_time, presence: true, numericality: { greater_than_or_equal_to: 0 }
    
    enum :status, { completed: 0, failed: 1 }
    
    # JSON columns handle serialization automatically
    # results structure: { steps: [...], final_output: "...", total_execution_time: 123 }
    # input_variables structure: { key: "value", ... }
    
    scope :recent, -> { order(created_at: :desc) }
    
    before_create :set_default_title
    
    private
    
    def set_default_title
      self.title ||= created_at.present? ? 
        created_at.strftime("%B %d, %Y at %I:%M %p") : 
        Time.current.strftime("%B %d, %Y at %I:%M %p")
    end
  end
end
