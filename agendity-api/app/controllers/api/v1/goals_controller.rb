# frozen_string_literal: true

module Api
  module V1
    class GoalsController < BaseController
      before_action :require_intelligent_plan!

      # GET /api/v1/goals
      def index
        goals = current_business.business_goals.active.order(:created_at)
        render_success(goals.as_json(only: [:id, :goal_type, :name, :target_value, :period, :fixed_costs, :active]))
      end

      # POST /api/v1/goals
      def create
        goal = current_business.business_goals.build(goal_params)
        if goal.save
          render_success(goal.as_json(only: [:id, :goal_type, :name, :target_value, :period, :fixed_costs, :active]), status: :created)
        else
          render_error(goal.errors.full_messages.join(", "), status: :unprocessable_entity)
        end
      end

      # PATCH /api/v1/goals/:id
      def update
        goal = current_business.business_goals.find(params[:id])
        if goal.update(goal_params)
          render_success(goal.as_json(only: [:id, :goal_type, :name, :target_value, :period, :fixed_costs, :active]))
        else
          render_error(goal.errors.full_messages.join(", "), status: :unprocessable_entity)
        end
      end

      # DELETE /api/v1/goals/:id
      def destroy
        goal = current_business.business_goals.find(params[:id])
        goal.destroy
        head :no_content
      end

      # GET /api/v1/goals/progress
      def progress
        result = Intelligence::GoalProgressService.call(business: current_business)
        if result.success?
          render_success(result.data)
        else
          render_error(result.error)
        end
      end

      private

      def require_intelligent_plan!
        unless current_business.has_feature?(:ai_features)
          render_error("Las metas financieras requieren Plan Inteligente.", status: :forbidden)
        end
      end

      def goal_params
        params.require(:goal).permit(:goal_type, :name, :target_value, :period, :fixed_costs, :active)
      end
    end
  end
end
