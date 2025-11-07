module Search
  class RoleBasedFilterService
    attr_reader :user, :collection_name

    def initialize(user, collection_name)
      @user = user
      @collection_name = collection_name
    end

    def apply_filters
      return [] if user.admin?

      case collection_name
      when 'orders'
        apply_order_filters
      when 'pods'
        apply_pod_filters
      when 'drivers'
        apply_driver_filters
      when 'fleets'
        apply_fleet_filters
      when 'billings', 'invoices', 'accounts'
        apply_billing_filters
      else
        []
      end
    end

    def can_access?
      user.can_search_collection?(collection_name)
    end

    private

    def apply_order_filters
      case user.role
      when 'dispatcher'
        # Dispatchers can see orders assigned to them or unassigned
        [
          {
            'compound' => {
              'should' => [
                { 'equals' => { 'path' => 'assigned_dispatcher_id', 'value' => user.id } },
                { 'equals' => { 'path' => 'assigned_dispatcher_id', 'value' => nil } }
              ]
            }
          }
        ]
      when 'driver'
        # Drivers can only see their assigned orders
        return [] unless user.driver_id

        [
          { 'equals' => { 'path' => 'driver_id', 'value' => user.driver_id } }
        ]
      when 'fleet_manager'
        # Fleet managers can see orders for their fleets
        # This would require fetching fleet IDs they manage
        []
      else
        []
      end
    end

    def apply_pod_filters
      case user.role
      when 'driver'
        # Drivers can only see their PODs
        return [] unless user.driver_id

        [
          { 'equals' => { 'path' => 'driver_id', 'value' => user.driver_id } }
        ]
      else
        []
      end
    end

    def apply_driver_filters
      case user.role
      when 'driver'
        # Drivers can only see their own record
        return [] unless user.driver_id

        [
          { 'equals' => { 'path' => '_id', 'value' => user.driver_id } }
        ]
      else
        []
      end
    end

    def apply_fleet_filters
      # Most roles can see all fleets (read-only for non-fleet managers)
      []
    end

    def apply_billing_filters
      # Billing department can see all
      []
    end
  end
end
