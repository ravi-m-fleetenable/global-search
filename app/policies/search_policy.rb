class SearchPolicy < ApplicationPolicy
  def global?
    user.present?
  end

  def autocomplete?
    user.present?
  end

  def facets?
    user.present?
  end

  def advanced?
    user.present?
  end

  # Check if user can search specific collection
  def can_search_collection?(collection_name)
    user.can_search_collection?(collection_name)
  end

  # Scope results based on role
  def apply_scope(collection)
    case user.role
    when 'admin'
      collection
    when 'dispatcher'
      apply_dispatcher_scope(collection)
    when 'billing'
      apply_billing_scope(collection)
    when 'driver'
      apply_driver_scope(collection)
    when 'fleet_manager'
      apply_fleet_manager_scope(collection)
    else
      collection.none
    end
  end

  private

  def apply_dispatcher_scope(collection)
    # Dispatchers can see orders assigned to them or unassigned
    case collection.model_name.name
    when 'Order'
      collection.or(
        { assigned_dispatcher_id: user.id },
        { assigned_dispatcher_id: nil }
      )
    else
      collection
    end
  end

  def apply_billing_scope(collection)
    # Billing can see all billing-related data
    collection
  end

  def apply_driver_scope(collection)
    # Drivers can only see their own data
    return collection.none unless user.driver_id

    case collection.model_name.name
    when 'Order'
      collection.where(driver_id: user.driver_id)
    when 'Pod'
      collection.where(driver_id: user.driver_id)
    when 'Driver'
      collection.where(id: user.driver_id)
    else
      collection.none
    end
  end

  def apply_fleet_manager_scope(collection)
    # Fleet managers can see all fleet-related data
    collection
  end
end
