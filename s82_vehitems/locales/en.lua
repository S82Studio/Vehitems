Locales = Locales or {}

Locales['en'] = {
    -- Confirm dialog
    ['confirm_header']  = 'Confirm item use',
    ['confirm_content'] = 'This is a special item, you will receive full ownership of this vehicle. Please choose an open area free of obstacles before using it.',
    ['confirm_confirm'] = 'Use',
    ['confirm_cancel']  = 'Cancel',

    -- Progress bar
    ['progress_label'] = 'Deploying vehicle...',

    -- Client-side errors
    ['err_busy']            = 'You are already in the middle of using another item!',
    ['err_in_vehicle']      = 'You cannot use this item while inside a vehicle!',
    ['err_in_interior']     = 'You cannot use this item indoors!',
    ['err_too_many_vehicles'] = 'There are too many vehicles nearby. Please move to a more open area!',
    ['err_too_many_objects']  = 'There are too many obstacles nearby. Please find a clearer spot!',
    ['err_invalid_position']  = 'Invalid location. Please try somewhere else!',
    ['err_interrupted']       = 'The process was interrupted!',

    -- Server-side errors
    ['err_cannot_identify']  = 'Unable to identify your character!',
    ['err_cooldown']         = 'You need to wait %s before using this item again.',
    ['err_already_flow']     = 'You are already in the middle of using an item!',
    ['err_no_item']          = 'You do not have this item!',
    ['err_invalid_session']  = 'Invalid item use session!',
    ['err_invalid_coords']   = 'Invalid spawn coordinates!',
    ['err_unsupported_item'] = 'This item is not supported!',
    ['err_item_gone']        = 'You no longer have this item!',
    ['err_register_failed']  = 'Failed to register the vehicle: %s',
    ['err_spawn_failed']     = 'Failed to spawn the vehicle, changes have been rolled back!',
    ['err_no_bridge']        = 'This script could not detect a supported framework/inventory. Please contact an administrator.',

    -- Success
    ['success_received'] = 'You received a %s! Plate: %s',

    -- Time formatting
    ['time_seconds']        = '%d seconds',
    ['time_minutes']        = '%d minutes',
    ['time_minutes_seconds'] = '%d minutes %d seconds',
}
