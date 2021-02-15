/**
    Gui Element

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.ui.gui_element;

import atelier.render, atelier.core, atelier.common, atelier.render;
import atelier.ui.gui_overlay;

/// Alignment on the horizontal axis relative to its parent.
enum GuiAlignX {
    left,
    center,
    right
}

/// Alignment on the vertical axis relative to its parent.
enum GuiAlignY {
    top,
    center,
    bottom
}

/// Single state of a GUI. \
/// Used with **addState**, **setState**, **doTransitionState** etc.
struct GuiState {
    /// Position offset relative to its alignment. (0 = No modification)
    Vec2f offset = Vec2f.zero;
    /// Size scale of the GUI. (1 = Default)
    Vec2f scale = Vec2f.one;
    /// Color of the GUI. (White = Default)
    Color color = Color.white;
    /// Opacity of the GUI (1 = Default)
    float alpha = 1f;
    /// Blend of the canvas if present (Alpha blending = Default)
    Blend blend = Blend.alpha;
    /// Angle of the GUI. (0 = Default)
    float angle = 0f;
    /// Time (in seconds) to get to this state with **doTransitionState()**.
    float time = .5f;
    /// When fully in this state, **onCallback()** will be called with **callback**.
    string callback;
    /// The easing algorithm used to get to this state.
    EasingFunction easing = &easeLinear;
}

/// Base class of all GUI elements.
class GuiElement {
    private {
        Canvas _canvas;
        bool _hasCanvas;
    }

    package {
        GuiElement[] _children;
        Hint _hint;
        bool _isRegistered = true;
        bool _isLocked, _isMovable, _isHovered, _isClicked, _isSelected,
            _hasFocus, _isInteractable = true, _hasEventHook;
        Vec2f _position = Vec2f.zero, _size = Vec2f.zero, _anchor = Vec2f.half,
            _padding = Vec2f.zero, _center = Vec2f.zero, _origin = Vec2f.zero;
        GuiElement _callbackGuiElement;
        string _callbackId;

        //Iteration
        bool _isIterating, _isWarping = true;
        uint _idChildIterator;
        Timer _iteratorTimer, _iteratorTimeOutTimer;

        Vec2f _screenCoords;
        GuiAlignX _alignX = GuiAlignX.left;
        GuiAlignY _alignY = GuiAlignY.top;

        //States
        string _currentStateName = "default";
        GuiState _currentState, _targetState, _initState;
        GuiState[string] _states;
        Timer _timer;
    }

    package void setScreenCoords(Vec2f screenCoords) {
        _screenCoords = screenCoords;
        if (_hasCanvas && _canvas !is null) {
            _center = _size / 2f;
            _origin = Vec2f.zero;
        }
        else {
            _center = screenCoords;
            _origin = _center - _size / 2f;
        }
    }

    @property {
        /// If set, the canvas used to be rendered on.
        final Canvas canvas() {
            return _canvas;
        }
        /// Is this GUI using a canvas ?
        final bool hasCanvas() const {
            return _hasCanvas;
        }
        /// Ditto
        final bool hasCanvas(bool hasCanvas_) {
            _hasCanvas = hasCanvas_;
            if(_hasCanvas) {
                if (_size.x > 2f && _size.y > 2f) {
                    _canvas = new Canvas(_size);
                    _canvas.position = _canvas.size / 2f;
                }
                else
                    _canvas = null;
            }
            else {
                _canvas = null;
            }
            return _hasCanvas;
        }

        /// The hint window to be shown when hovering this GUI.
        final Hint hint() {
            return _hint;
        }

        /// The list of all its children.
        const(GuiElement[]) children() const {
            return _children;
        }
        /// Ditto
        GuiElement[] children() {
            return _children;
        }

        /// Return the first child gui.
        GuiElement firstChild() {
            if (!_children.length)
                return null;
            return _children[0];
        }

        /// Return the last child gui.
        GuiElement lastChild() {
            if (!_children.length)
                return null;
            return _children[$ - 1];
        }

        /// The number of children it currently has.
        size_t childCount() const {
            return _children.length;
        }

        /// Is this gui locked ? \
        /// Call **onLock()** on change.
        final bool isLocked() const {
            return _isLocked;
        }
        /// Ditto
        final bool isLocked(bool isLocked_) {
            if (isLocked_ != _isLocked) {
                _isLocked = isLocked_;
                onLock();
                return _isLocked;
            }
            return _isLocked = isLocked_;
        }

        /// Is this gui movable ? \
        /// Call **onMovable()** on change.
        final bool isMovable() const {
            return _isMovable;
        }
        /// Ditto
        final bool isMovable(bool isMovable_) {
            if (isMovable_ != _isMovable) {
                _isMovable = isMovable_;
                onMovable();
                return _isMovable;
            }
            return _isMovable = isMovable_;
        }

        /// Is this gui hovered ? \
        /// Call **onHover()** on change. (<- Not for now)
        final bool isHovered() const {
            return _isHovered;
        }
        /// Ditto
        final bool isHovered(bool isHovered_) {
            if (isHovered_ != _isHovered) {
                _isHovered = isHovered_;
                onHover();
                return _isHovered;
            }
            return _isHovered = isHovered_;
        }

        /// Is this gui clicked ?
        final bool isClicked() const {
            return _isClicked;
        }
        /// Ditto
        final bool isClicked(bool isClicked_) {
            return _isClicked = isClicked_;
        }

        /// Is this gui selected ? \
        /// Call **onSelect()** on change.
        final bool isSelected() const {
            return _isSelected;
        }
        /// Ditto
        final bool isSelected(bool isSelected_) {
            if (isSelected_ != _isSelected) {
                _isSelected = isSelected_;
                onSelect();
                return _isSelected;
            }
            return _isSelected = isSelected_;
        }

        /// Does this gui has focus ? \
        /// Call **onFocus()** on change.
        final bool hasFocus() const {
            return _hasFocus;
        }
        /// Ditto
        final bool hasFocus(bool hasFocus_) {
            if (hasFocus_ != _hasFocus) {
                _hasFocus = hasFocus_;
                onFocus();
                return _hasFocus;
            }
            return _hasFocus = hasFocus_;
        }

        /// Is this gui interactable ? \
        /// Call **onInteractable()** on change.
        final bool isInteractable() const {
            return _isInteractable;
        }
        /// Ditto
        final bool isInteractable(bool isInteractable_) {
            if (isInteractable_ != _isInteractable) {
                _isInteractable = isInteractable_;
                onInteractable();
                return _isInteractable;
            }
            return _isInteractable = isInteractable_;
        }

        /// The gui position relative to its parent and alignment. \
        /// Call **onPosition()** and **onDeltaPosition()** and **onCenter()** on change.
        final Vec2f position() {
            return _position;
        }
        /// Ditto
        final Vec2f position(Vec2f position_) {
            auto oldPosition = _position;
            _position = position_;
            onDeltaPosition(position_ - oldPosition);
            onPosition();
            onCenter();
            return _position;
        }

        /// The scale of the gui (changed by GuiState).
        final Vec2f scale() const {
            return _currentState.scale;
        }
        /// Ditto
        final Vec2f scale(Vec2f scale_) {
            return _currentState.scale = scale_;
        }
        /// The total size (size + scale) of the gui.
        final Vec2f scaledSize() const {
            return _size * _currentState.scale;
        }

        /// The unscaled size of the gui. \
        /// Call **onSize()** and **onDeltaSize()** and **onCenter()** on change. \
        /// Resize the canvas if it was set (It reallocate the canvas, so be careful).
        final Vec2f size() const {
            return _size;
        }
        /// Ditto
        final Vec2f size(Vec2f size_) {
            auto oldSize = _size;
            _size = size_ - _padding;

            if (_hasCanvas && oldSize != size_) {
                if (_size.x > 2f && _size.y > 2f) {
                    _canvas = new Canvas(_size);
                    _canvas.position = _canvas.size / 2f;
                }
                else
                    _canvas = null;
            }

            onDeltaSize(_size - oldSize);
            onSize();
            onCenter();
            return _size;
        }

        /// The anchor of the gui. (I don't think it's used right now). \
        /// Call **onAnchor()** and **onDeltaAnchor()** and **onCenter()** on change.
        final Vec2f anchor() const {
            return _anchor;
        }
        /// Ditto
        final Vec2f anchor(Vec2f anchor_) {
            auto oldAnchor = _anchor;
            _anchor = anchor_;
            onDeltaAnchor(anchor_ - oldAnchor);
            onAnchor();
            onCenter();
            return _anchor;
        }

        /*
            Old algorithm:
            _position + _size * (Vec2f.half - _anchor);
        */

        /// Center of the gui. \
        /// If the canvas is set, only drawOverlay have the coordinate of its parent, the rest are in a relative coordinate.
        final Vec2f center() const {
            return _center;
        }
        /// The top left corner of the gui. \
        /// If the canvas is set, only drawOverlay have the coordinate of its parent, the rest are in a relative coordinate.
        final Vec2f origin() const {
            return _origin;
        }

        /// Extra space on top of its size. \
        /// Call **onPadding()** and update the gui size.
        final Vec2f padding() const {
            return _padding;
        }
        /// Ditto
        final Vec2f padding(Vec2f padding_) {
            _padding = padding_;
            size(_size);
            onPadding();
            return _padding;
        }

        /// Color of the actual state (GuiState) of the gui. \
        /// Call **onColor()** on change.
        final Color color() const {
            return _currentState.color;
        }
        /// Ditto
        final Color color(Color color_) {
            if (color_ != _currentState.color) {
                _currentState.color = color_;
                onColor();
            }
            return _currentState.color;
        }

        /// Alpha of the actual state (GuiState) of the gui. \
        /// Call **onAlpha()** on change.
        final float alpha() const {
            return _currentState.alpha;
        }
        /// Ditto
        final float alpha(float alpha_) {
            if (alpha_ != _currentState.alpha) {
                _currentState.alpha = alpha_;
                onAlpha();
            }
            return _currentState.alpha;
        }

        /// Angle of the actual state (GuiState) of the gui.
        final float angle() const {
            return _currentState.angle;
        }
        /// Ditto
        final float angle(float angle_) {
            _currentState.angle = angle_;
            onAngle();
            return _currentState.angle;
        }
    }

    /// Gui initialization options
    enum Init {
        /// Default
        none = 0x0,
        /// Is focused ?
        focus = 0x1,
        /// Initialize the gui locked
        locked = 0x2,
        /// The gui can be moved around with the mouse
        movable = 0x4,
        /// The gui will ignore mouse events
        notInteractable = 0x8,
        /// The gui will receive mouse events that are destined to its children
        eventHook = 0x10
    }

    /// Default ctor.
    this() {}

    /// Default ctor.
    protected final void setInitFlags(int options = Init.none) {
        _hasFocus = cast(bool)(options & Init.focus);
        _isLocked = cast(bool)(options & Init.locked);
        _isMovable = cast(bool)(options & Init.movable);
        _isInteractable = cast(bool) !(options & Init.notInteractable);
        _hasEventHook = cast(bool)(options & Init.eventHook);
    }

    /// Is it inside the gui ?
    bool isInside(const Vec2f pos) const {
        return (_screenCoords - pos).isBetween(-_size / 2f, _size / 2f);
    }

    /// Is it inside the gui and the gui is interactable ? \
    /// Used to capture events.
    final bool isOnInteractableGuiElement(Vec2f pos) const {
        if (isInside(pos))
            return _isInteractable;
        return false;
    }

    /// Update the hint (Text that appear when hovering the gui) of the gui.
    final void setHint(string text) {
        _hint = makeHint(text);
    }

    /// Set an id that will be sent to the specified gui when **triggerCallback()** is fired.
    final void setCallback(GuiElement callbackGuiElement, string callback) {
        _callbackGuiElement = callbackGuiElement;
        _callbackId = callback;
    }

    /// Send a previously set (with **setCallback()**) id to the previously specified gui.
    final protected void triggerCallback() {
        if (_callbackGuiElement !is null) {
            _callbackGuiElement.onCallback(_callbackId);
        }
    }

    /// Start a transition from the current state to the specified state.
    final void doTransitionState(string stateName) {
        const auto ptr = stateName in _states;
        if (!(ptr))
            throw new Exception("No state " ~ stateName ~ " in GuiElement");
        _currentStateName = stateName;
        _initState = _currentState;
        _targetState = *ptr;
        _timer.start(_targetState.time);
    }

    /// The gui is set *immediately* to the specified state without transition.
    final void setState(string stateName) {
        const auto ptr = stateName in _states;
        if (!(ptr))
            throw new Exception("No state " ~ stateName ~ " in GuiElement");
        _currentStateName = stateName;
        _initState = *ptr;
        _targetState = *ptr;
        _currentState = *ptr;
    }

    /// Current state name or currently transitioning to.
    final string getState() const {
        return _currentStateName;
    }

    /// Add a new state to the list.
    final void addState(string stateName, GuiState state) {
        _states[stateName] = state;
    }

    /// Does this gui receive events (with **onEvent()**) ?
    final void setEventHook(bool hasHook) {
        _hasEventHook = hasHook;
    }

    /// Sets the alignment relative to its parent. \
    /// Position will be calculated from the specified alignement.
    final void setAlign(GuiAlignX x, GuiAlignY y) {
        _alignX = x;
        _alignY = y;
    }

    /// Override this to set the gui logic.
    /// The deltaTime is the time ratio for the last frame to the next.
    /// It is equivallent to Actual framerate / Nominal framerate.
    /// Ideally, it's equal to 1.
    /// ___
    /// If the canvas is set, the coordinate are those *inside* the canvas.
    void update(float deltaTime) {
        cast(void) deltaTime;
    }

    /// Override this to render the gui itself. \
    /// If the canvas is set, the coordinate are those *inside* the canvas.
    void draw() {
    }

    /// Override this to render things above the gui. \
    /// If the canvas is set, the coordinate are those *outside* the canvas.
    void drawOverlay() {
    }

    /// With the eventHook, receive all events. \
    /// Useful if you want to control like for text input. 
    void onEvent(Event event) {
        cast(void) event;
    }

    /// Fired when clicked on.
    void onSubmit() {
    }

    /// Fired upon cancelling.
    void onCancel() {
    }

    /// Fired on the next tab event.
    void onNextTab() {
    }

    /// Fired on the previous tab event.
    void onPreviousTab() {
    }

    /// Fired when going up.
    void onUp() {
    }

    /// Fired when going down.
    void onDown() {
    }

    /// Fired when going left.
    void onLeft() {
    }

    /// Fired when going right.
    void onRight() {
    }

    /// Fired when the application is exiting. \
    /// Every gui in the tree receive this.
    void onQuit() {
    }

    public {
        /// Called when the lock state is changed.
        void onLock() {
        }

        /// Called when the movable state is changed.
        void onMovable() {
        }

        /// Called when the hover state is changed.
        void onHover() {
        }

        /// Called when the select state is changed.
        void onSelect() {
        }

        /// Called when the focus state is changed.
        void onFocus() {
        }

        /// Called when the interactable state is changed.
        void onInteractable() {
        }

        /// Called when the position is changed. \
        /// The delta value is the difference with the last position.
        void onDeltaPosition(Vec2f delta) {
            cast(void) delta;
        }

        /// Called when the position is changed.
        void onPosition() {
        }

        /// Called when the size is changed. \
        /// The delta value is the difference with the last size.
        void onDeltaSize(Vec2f delta) {
            cast(void) delta;
        }

        /// Called when the size is changed.
        void onSize() {
        }

        /// Called when the anchor is changed. \
        /// The delta value is the difference with the last anchor.
        void onDeltaAnchor(Vec2f delta) {
            cast(void) delta;
        }

        /// Called when the anchor is changed.
        void onAnchor() {
        }

        /// Called when the center of the gui moved.
        void onCenter() {
        }

        /// Called when the padding change.
        void onPadding() {
        }

        /// Called when the color change.
        void onColor() {
        }

        /// Called when the opacity change.
        void onAlpha() {
        }

        /// Called when the angle change.
        void onAngle() {
        }

        /// Any callback set to this gui will call this.
        void onCallback(string id) {
            cast(void) id;
        }
    }

    /// Add a gui as a child of this one.
    void prependChild(GuiElement child) {
        _children = child ~ _children;
    }

    /// Add a gui as a child of this one.
    void appendChild(GuiElement child) {
        _children ~= child;
    }

    /// Remove all the children.
    void removeChildren() {
        _children.length = 0uL;
    }

    /// Remove the child at the specified index.
    void removeChild(size_t index) {
        if (!_children.length)
            return;
        if (index + 1u == _children.length)
            _children.length--;
        else if (index == 0u)
            _children = _children[1 .. $];
        else
            _children = _children[0 .. index] ~ _children[index + 1 .. $];
    }

    /// Remove the specified child.
    void removeChild(GuiElement gui) {
        foreach (size_t i, GuiElement child; _children) {
            if (child is gui) {
                removeChild(i);
                return;
            }
        }
    }

    /// Unregister itself from its parent or root.
    void removeSelf() {
        _isRegistered = false;
    }
}
