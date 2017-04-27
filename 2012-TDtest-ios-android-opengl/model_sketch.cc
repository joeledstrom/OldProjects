Model sketch


class Map {
	
};





class GameState {
	vector<Unit> units;
	uint_64t time; //ms
	int currentWave;
	shared_ptr<Map> map;
};


// Action examples:
// Charging(Unit& target)
// Knockback(vec3 vel, vec3 accel)
// MeleeAttack(Unit& target)
class Action {
	
};

namespace UnitState {
	enum UnitState {
		INACTIVE,
		PREVIEW,   // show preview of incoming wave
		IDLE, // unit just spawned
		
	};
}

class Unit {
	vec3 position;
	UnitState state;
	Action action;  // default Action.EMPTY
	
	void update(dt) { // NOT called if state: INACTIVE|PREVIEW
		
		
		// if action = Action.EMPTY
		//   onUpdate(dt)
		// else
		//   action.onUpdate(*this, dt);
	}
	virtual void onUpdate(dt) = 0;
	
};



class BasicSoldier {
	virtual void onUpdate() {
		switch (state) {
		case IDLE:
			// build aggro list, if not exists
			// if in range, set: action = MeleeAttack(...)
			// find path to target, walk path
			break;
		}
	}
};


