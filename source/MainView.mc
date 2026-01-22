import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Application;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Timer;
import Toybox.Attention;
import Toybox.Application.Storage;
import Toybox.System;

var match_length = null;

var p2Score_ctr = 0;
var p1Score_ctr = 0;
var p1Score = null;
var p2Score = null;
var p1Set_ctr = 0;
var p2Set_ctr = 0;
var p1Set = null;
var p2Set = null;
var total_points = 0;
var whoServes = 1;
var setServer = whoServes;
var updateTimer = null;
var bestofTextLabel = null;
var bestofNumberLabel = null;

var p1Label = null;
var p2Label = null;

var matchStack = new Stack();
var vibeTimer = null;

class MainView extends WatchUi.View {

    function initialize() {
        View.initialize();

        if (Application.Properties.getValue("match_length") != null) {
            match_length = Application.Properties.getValue("match_length");
        } else {
            match_length = 5; // Default to best of 5
        }

        // -------------------------------

        if (updateTimer != null) {
            updateTimer.stop();
        }
        updateTimer = new Timer.Timer();
        updateTimer.start(method(:timerCallback), 1000, true);
    }

    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
        bestofTextLabel = findDrawableById("match_length_label") as WatchUi.Text;
        updateBestOfText();
        p1Score = findDrawableById("p1_score") as WatchUi.Text;
        p2Score = findDrawableById("p2_score") as WatchUi.Text;
        p1Set = findDrawableById("p1_set") as WatchUi.Text;
        p2Set = findDrawableById("p2_set") as WatchUi.Text;
        p1Label = findDrawableById("p1_label") as WatchUi.Text;
        p2Label = findDrawableById("p2_label") as WatchUi.Text;
    }

    function onUpdate(dc as Dc) as Void {
        View.onUpdate(dc);
        var clockTime = System.getClockTime();
        var timeString = Lang.format("$1$:$2$", [clockTime.hour, clockTime.min.format("%02d")]);
        var timeView = findDrawableById("time_label") as WatchUi.Text;
        timeView.setText(timeString);
        updateBestOfText();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE); // Set border color
        dc.setPenWidth(1); // Set border width
        dc.drawRoundedRectangle((dc.getWidth() / 2) - 40 , dc.getHeight() - (dc.getHeight()/7), 80, 60, 10);
        dc.setPenWidth(2); 

        if (whoServes == 1) {
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLUE);
            dc.setPenWidth(3);
            dc.drawRoundedRectangle(30, 100, 100, 120, 10);
        } else if (whoServes == 2) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
            dc.setPenWidth(3);
            dc.drawRoundedRectangle(230, 100, 100, 120, 10);
        }
    }

    function updateBestOfText() as Void {
        if (bestofTextLabel == null) { return; }
        
        var template = WatchUi.loadResource(Rez.Strings.BestOf) as String;
        var formatted = Lang.format(template, [match_length as Number]); 
        
        bestofTextLabel.setText(formatted);
    }



    function timerCallback() as Void {
        WatchUi.requestUpdate();
    }

    function delayedVibe() as Void {
        Attention.vibrate(matchOverVibeProfile);
    }

    function onP1Score() as Void {
        if (p1Score != null) {
            matchStack.push(p1Score_ctr, p1Set_ctr, p2Score_ctr, p2Set_ctr, total_points, whoServes);
            p1Score_ctr++;
            p1Score.setText(p1Score_ctr.toString());
            matchLogic();
        }
    }

    function onP2Score() as Void {
        if (p2Score != null) {
            matchStack.push(p1Score_ctr, p1Set_ctr, p2Score_ctr, p2Set_ctr, total_points, whoServes);
            p2Score_ctr++;
            p2Score.setText(p2Score_ctr.toString());
            matchLogic();
        }
    }

    function onUndoOrSwitch() as Void {
        if (total_points == 0 && p1Set_ctr == 0 && p2Set_ctr == 0) {
            switchServer();
            setServer = whoServes;
        } else {
            var lastEntry = matchStack.pop();
            if (lastEntry != null) {
                p1Score_ctr = lastEntry.p1;
                p1Set_ctr = lastEntry.p1Sets;
                p2Score_ctr = lastEntry.p2;
                p2Set_ctr = lastEntry.p2Sets;
                total_points = lastEntry.points;
                whoServes = lastEntry.serving;
                p1Score.setText(p1Score_ctr.toString());
                p1Set.setText(p1Set_ctr.toString());
                p2Score.setText(p2Score_ctr.toString());
                p2Set.setText(p2Set_ctr.toString());
            }
        }
    }
    
    function matchLogic() as Void {
        //! @brief Main match logic function.
        //!
        //! This function contains the core logic for processing and managing the match.
        //! It handles the primary flow of the match, including state updates, event handling,
        //! and determining match outcomes.
        //!
        //! @param ... (describe parameters here if any)
        //! @return ... (describe return value if any)
        toggleServer();
        total_points++;

        if (isDeuce()) {
            if (p1Score_ctr - p2Score_ctr == 2) {
                p1Set_ctr++;
                p1Set.setText(p1Set_ctr.toString());
                if (vibeTimer != null) { vibeTimer.stop(); }
                vibeTimer = new Timer.Timer();
                vibeTimer.start(method(:delayedVibe), 150, false);
                isOver();
                resetGame();
            } else if (p2Score_ctr - p1Score_ctr == 2) {
                p2Set_ctr++;
                p2Set.setText(p2Set_ctr.toString());
                if (vibeTimer != null) { vibeTimer.stop(); }
                vibeTimer = new Timer.Timer();
                vibeTimer.start(method(:delayedVibe), 150, false);
                isOver();
                resetGame();
            }
        } else {
            if (p1Score_ctr == 11) {
                p1Set_ctr++;
                p1Set.setText(p1Set_ctr.toString());
                if (vibeTimer != null) { vibeTimer.stop(); }
                vibeTimer = new Timer.Timer();
                vibeTimer.start(method(:delayedVibe), 150, false);
                isOver();
                resetGame();
            } else if (p2Score_ctr == 11) {
                p2Set_ctr++;
                p2Set.setText(p2Set_ctr.toString());
                if (vibeTimer != null) { vibeTimer.stop(); }
                vibeTimer = new Timer.Timer();
                vibeTimer.start(method(:delayedVibe), 150, false);
                isOver();
                resetGame();
            }
        }
    }

    function isDeuce() as Boolean {
        return (p1Score_ctr >= 10 && p2Score_ctr >= 10);
    }

    function isOver() as Void {
        // Math.ceil doesn't work as expected, this is a workaround
        var setsToWin = Math.floor(match_length / 2) + 1;
        var p1Name, p2Name;

        p1Name = WatchUi.loadResource(Rez.Strings.Player1Name) as String;
        p2Name = WatchUi.loadResource(Rez.Strings.Player2Name) as String;

        var message = WatchUi.loadResource(Rez.Strings.MatchWin) as String;

        if (p1Set_ctr >= setsToWin) {
            System.println(p1Name + " " + message);
            Attention.vibrate(matchOverVibeProfile);
            var view = new WinningView(p1Name + " " + message);
            WatchUi.pushView(view, null, WatchUi.SLIDE_UP);
            resetMatch();
        } else if (p2Set_ctr >= setsToWin) {
            System.println(p2Name + " " + message);
            Attention.vibrate(matchOverVibeProfile);
            var view = new WinningView(p2Name + " " + message);
            WatchUi.pushView(view, null, WatchUi.SLIDE_UP);
            resetMatch();
        }
    }

    function switchServer() as Void {
        whoServes = (whoServes == 1) ? 2 : 1;
    }

    function settingServer() as Void {
        setServer = (setServer == 1) ? 2 : 1;
        whoServes = setServer;
    }

    function toggleServer() as Void {
        if (isDeuce()) {
            switchServer();
        } else {
            if (total_points % 2 == 1) {
                switchServer();
            }
        }
    }

    function resetGame() as Void {
        p1Score_ctr = 0;
        p2Score_ctr = 0;
        total_points = 0;
        p1Score.setText(p1Score_ctr.toString());
        p2Score.setText(p2Score_ctr.toString());
        settingServer();
    }

    function resetMatch() as Void {
        resetGame();
        matchStack = new Stack();
        p1Set_ctr = 0;
        p2Set_ctr = 0;
        p1Set.setText(p1Set_ctr.toString());
        p2Set.setText(p2Set_ctr.toString());
        whoServes = 1;
        setServer = whoServes;
    }

}

class WinningView extends WatchUi.View {
    var winnerName;

    function initialize(name as String) {
        View.initialize();
        winnerName = name;
    }

    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.GameOverLayout(dc));
        var winner = findDrawableById("winning_player") as WatchUi.Text;
        if (winner != null) {
            winner.setText(winnerName);
        }
    }
}