import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Attention;
import Toybox.System;

var scoreVibeProfile = [new Attention.VibeProfile(75, 150)];

var undoVibeProfile = [
    new Attention.VibeProfile(100, 100),  // Strong 100ms buzz
    new Attention.VibeProfile(0, 50),     // 50ms pause (was backwards)
    new Attention.VibeProfile(100, 100)   // Strong 100ms buzz
];

var matchOverVibeProfile = [
    new Attention.VibeProfile(100, 200),  // Strong 200ms buzz
    new Attention.VibeProfile(0, 100),    // 100ms pause
    new Attention.VibeProfile(100, 200)   // Strong 200ms buzz
];

var exitMenuVibeProfile = [
    new Attention.VibeProfile(100, 300),   // Mild 300ms buzz
    new Attention.VibeProfile(0, 100),    // 100ms pause
    new Attention.VibeProfile(100, 300),   // Mild 300ms buzz
    new Attention.VibeProfile(0, 100),    // 100ms pause
    new Attention.VibeProfile(100, 300)    // Mild 300ms buzz
];

var backButtonHeld = false;

class MainDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();

        if (key == WatchUi.KEY_ESC) { // Bottom Button (physical back/escape)
            if (!backButtonHeld) {
                new MainView().onP2Score();
                Attention.vibrate(scoreVibeProfile);
                WatchUi.requestUpdate();
            }
            return true;
        } else if (key == WatchUi.KEY_ENTER) { // Top Button
            new MainView().onP1Score();
            Attention.vibrate(scoreVibeProfile);
            WatchUi.requestUpdate();
            return true;
        } else if (key == WatchUi.KEY_MENU) { // Menu
            new MainView().onUndoOrSwitch();
            Attention.vibrate(undoVibeProfile);
            WatchUi.requestUpdate();
            return true;
        }

        return false;
    }

    function onKeyDown(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        
        if (key == WatchUi.KEY_ESC) { // Bottom Button held
            backButtonHeld = true;
            new MainView().onUndoOrSwitch();
            Attention.vibrate(undoVibeProfile);
            WatchUi.requestUpdate();
            return true;
        }
        
        return false;
    }

    function onKeyUp(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        
        if (key == WatchUi.KEY_ESC) { // Bottom Button released
            backButtonHeld = false;
        }
        
        return false;
    }

    function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean {
        var direction = swipeEvent.getDirection();
        if (direction == WatchUi.SWIPE_RIGHT) {
            WatchUi.pushView(new WatchUi.Confirmation("Exit App?"), new ExitConfirmationDelegate(), WatchUi.SLIDE_UP);
            Attention.vibrate(exitMenuVibeProfile);
            return true;
        }
        return false;
    }

}

class ExitConfirmationDelegate extends WatchUi.ConfirmationDelegate {
    function initialize() {
        ConfirmationDelegate.initialize();
    }

    function onResponse(response) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        }
        return true;
    }
}