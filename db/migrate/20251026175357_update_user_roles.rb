class UpdateUserRoles < ActiveRecord::Migration[7.0]
  def up
    # Update all existing non-admin users (role = 0, which is 'member') to 'player' (role = 1)
    # Admin users (role = 1) need to be updated to role = 2
    # But first, let's safely update in the right order to avoid conflicts
    
    # Step 1: Update admins to a temporary value
    execute "UPDATE users SET role = 99 WHERE role = 1"
    
    # Step 2: Update members (role = 0) to players (role = 1) 
    execute "UPDATE users SET role = 1 WHERE role = 0"
    
    # Step 3: Update temp admins (role = 99) to admin (role = 2)
    execute "UPDATE users SET role = 2 WHERE role = 99"
    
    # New users will default to viewer (role = 0) going forward
    change_column_default :users, :role, 0
  end

  def down
    # Reverse the migration
    # Update admins back to role = 1
    execute "UPDATE users SET role = 1 WHERE role = 2"
    
    # Update players back to role = 0 
    execute "UPDATE users SET role = 0 WHERE role = 1"
    
    # Restore original default
    change_column_default :users, :role, 0
  end
end
