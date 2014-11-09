/**
 * adds a bindScoped method to Mousetrap that allows you to
 * bind specific keyboard shortcuts that will work only within
 * certain context
 * inside a text input field
 *
 * usage:
 * Mousetrap.bindScoped('.some-class', 'ctrl+s', _saveChanges);
 */
Mousetrap = (function(Mousetrap) {
    var _scopedCallbacks = {},
        _originalStopCallback = Mousetrap.stopCallback;

    Mousetrap.stopCallback = function(e, element, combo, sequence) {
        var selector = _scopedCallbacks[combo] || _scopedCallbacks[sequence];
        if (selector) {
            return !$(element).is(selector);
        }

        return _originalStopCallback(e, element, combo);
    };

    Mousetrap.bindScoped = function(selector, keys, callback, action) {
        Mousetrap.bind(keys, callback, action);

        if (keys instanceof Array) {
            for (var i = 0; i < keys.length; i++) {
                _scopedCallbacks[keys[i]] = selector;
            }
            return;
        }

        _scopedCallbacks[keys] = selector;
    };

    return Mousetrap;
}) (Mousetrap);
