/** 
 * Copyright: Enalye
 * License: Zlib
 * Authors: Enalye
 */
module etabli.input.map;

import std.algorithm.mutation : remove;

import etabli.input.event;

/// Gère l’association de certaines entrés avec leurs actions correspondantes
final class InputMap {
    /// Associe une action à un événement
    final class Action {
        /// Nom de l’action
        string id;

        /// Événements activant l’action
        InputEvent[] events;

        /// Init
        this(string id_) {
            id = id_;
        }

        /// L’événement active-t’il cette action ?
        bool match(InputEvent event_) {
            foreach (InputEvent event; events) {
                if (event.matchInput(event_)) {
                    return true;
                }
            }

            return false;
        }
    }

    private {
        Action[string] _actions;
    }

    /// Ajoute une nouvelle action
    void addAction(string id) {
        _actions[id] = new Action(id);
    }

    /// Retire une action existante
    void removeAction(string id) {
        _actions.remove(id);
    }

    /// Vérifie si une action existe
    bool hasAction(string id) const {
        auto p = id in _actions;
        return p !is null;
    }

    /// Retourne l’action
    Action getAction(string id) {
        auto p = id in _actions;
        return p ? *p : null;
    }

    /// Associe un événement à une action existante
    void addActionEvent(string id, InputEvent event) {
        auto p = id in _actions;

        if (!p) {
            return;
        }

        (*p).events ~= event;
    }

    /// Supprime un événement associé à une action
    void removeActionEvents(string id, InputEvent event) {
        auto p = id in _actions;

        if (!p) {
            return;
        }

        for (size_t i; i < (*p).events.length; ++i) {
            if ((*p).events[i] == event) {
                (*p).events = (*p).events.remove(i);
                break;
            }
        }
    }

    /// Supprime tous les événements associés à une action
    void removeActionEvents(string id) {
        auto p = id in _actions;

        if (!p) {
            return;
        }

        (*p).events.length = 0;
    }

    string[] getActions() {
        return _actions.keys;
    }

    Action getAction(InputEvent event) {
        foreach (Action action; _actions) {
            if (action.match(event)) {
                return action;
            }
        }

        return null;
    }
}
