-- ============================================================
-- Fix : le trigger user_events → notification_queue echoue
-- car la RLS n'autorise que SELECT sur notification_queue.
--
-- Solution : passer les fonctions trigger en SECURITY DEFINER
-- pour qu'elles s'executent avec les droits du owner (postgres).
-- ============================================================

-- 1. fn_schedule_user_event_notifications (insert user_events → queue)
ALTER FUNCTION fn_schedule_user_event_notifications() SECURITY DEFINER;

-- 2. fn_cancel_user_event_notifications (delete user_events → cancel queue)
ALTER FUNCTION fn_cancel_user_event_notifications() SECURITY DEFINER;

-- 3. fn_schedule_notifications (insert establishment_events → queue)
ALTER FUNCTION fn_schedule_notifications() SECURITY DEFINER;

-- 4. fn_reschedule_notifications (update establishment_events → update queue)
ALTER FUNCTION fn_reschedule_notifications() SECURITY DEFINER;

-- 5. fn_cancel_notifications (delete establishment_events → cancel queue)
ALTER FUNCTION fn_cancel_notifications() SECURITY DEFINER;

-- 6. fn_like_schedule (insert like → queue)
ALTER FUNCTION fn_like_schedule() SECURITY DEFINER;

-- 7. fn_unlike_cancel (delete like → cancel queue)
ALTER FUNCTION fn_unlike_cancel() SECURITY DEFINER;
