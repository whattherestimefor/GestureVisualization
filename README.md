# GestureVisualization
A sample app to get visual feedback from UIGestureRecognizer subclasses.

The view controller is already set up to create a few GestureVisualizers and stick them in the view.

If you want to observe a custom gesture recognizer, it will be assumed to be a continuous gesture.  If that is not the case, you'll have to add that information in isVisualizingDiscreteGesture().

This project adds some small delays to the visual feedback when messages start to stack up.  Otherwise, transitions would happen so quickly that you wouldn't be able to see them.

To visualize the state transitions, this app does key value observing on the state of the gesture.  DO NOT DO THIS in a shipping application!  UIGestureRecognizers are meant to be dealt with through their action messages to their targets.  Trying to respond to their internal state changes will only bring pain and misery.
