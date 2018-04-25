/**
Grimoire
Copyright (c) 2017 Enalye

This software is provided 'as-is', without any express or implied warranty.
In no event will the authors be held liable for any damages arising
from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute
it freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented;
	   you must not claim that you wrote the original software.
	   If you use this software in a product, an acknowledgment
	   in the product documentation would be appreciated but
	   is not required.

	2. Altered source versions must be plainly marked as such,
	   and must not be misrepresented as being the original software.

	3. This notice may not be removed or altered from any source distribution.
*/

module core.particlefilter;

import std.typecons;
import std.conv: to;

import core.util;
import core.vec2;
import core.color;
import core.stream;
import core.particle;

class ParticleFilter {
	protected {
		Vec2f _position = Vec2f.zero;
		Vec2f _size = Vec2f.one * 100f;
		int _id = -1;
		uint _nbProperties = 0U;
		bool _isCircle = false;
	}

	@property {
		int id() { return _id; }

		Vec2f position() const { return _position; }
		Vec2f position(Vec2f newPosition) { return _position = newPosition; }
	}

	bool isInside(const Vec2f pos) const {
		if(_isCircle)
			return _position.distanceSquared(pos) < _size.x * _size.x;
		else
			return pos.isBetween(_position - _size / 2f, _position + _size / 2f);
	}

	void apply(Particle particle, float deltaTime) {
		if(isInside(particle.position))
			updateParticle(particle, deltaTime);
	}

	protected abstract void updateParticle(Particle particle, float deltaTime);

	alias FilterProperty = Tuple!(string, float, float, uint);
	abstract FilterProperty[] getProperties() const;
	abstract float property(uint id) const;
	abstract void property(uint id, float newValue);

	alias FilterDisplay = Tuple!(string, const bool, const Vec2f, bool, const Vec2f, const Color);
	abstract FilterDisplay getDisplay() const;

	void save(OutStream stream) const {
		stream.write!float(_position.x);
		stream.write!float(_position.y);
		foreach(uint id; 0.._nbProperties)
			stream.write!float(property(id));
	}

	void load(InStream stream) {
		_position = Vec2f(stream.read!float(), stream.read!float());
		foreach(uint id; 0.._nbProperties)
			property(id, stream.read!float());
	}
}

//Force Filter
final class ForceFilterCircle: ParticleFilter {
	private	{
		float _angle = 0f, _acceleration = 0f;
		Vec2f _force = Vec2f.zero;
	}

	this() {
		_id = 0;
		_nbProperties = 3U;
		_isCircle = true;
	}

	override float property(uint id) const {
		switch(id) {
		case 0:
			return _size.x;
		case 1:
			return _angle;
		case 2:
			return _acceleration;
		default:
			throw new Exception("Filter property out of range");
		}
	}

	override void property(uint id, float newValue) {
		switch(id) {
		case 0:
			_size.x = newValue;
			_size.y = newValue;
			break;
		case 1:
			_angle = newValue;
			_force = Vec2f.angled(_angle) * _acceleration;
			break;
		case 2:
			_acceleration = newValue;
			_force = Vec2f.angled(_angle) * _acceleration;
			break;
		default:
			throw new Exception("Filter property out of range");
		}
	}

	protected override void updateParticle(Particle particle, float deltaTime) {
		particle.velocity += _force * deltaTime;
	}

	override FilterProperty[] getProperties() const {
		return [
			tuple("Rayon", 1f, 1000f, 999u),
			tuple("Angle", 0f, 360f, 360u),
			tuple("Accel.", 0f, 0.5f, 1000u)
			];
	}

	override FilterDisplay getDisplay() const {
		return tuple("Force", _isCircle, _size, true, cast(const Vec2f)(_force * 1000f), Color.red);
	}
}

final class ForceFilterRect: ParticleFilter {
	private	{
		float _angle = 0f, _acceleration = 0f;
		Vec2f _force = Vec2f.zero;
	}

	this() {
		_id = 1;
		_nbProperties = 4U;
		_isCircle = false;
	}

	override float property(uint id) const {
		switch(id) {
		case 0:
			return _size.x;
		case 1:
			return _size.y;
		case 2:
			return _angle;
		case 3:
			return _acceleration;
		default:
			throw new Exception("Filter property out of range");
		}
	}

	override void property(uint id, float newValue) {
		switch(id) {
		case 0:
			_size.x = newValue;
			break;
		case 1:
			_size.y = newValue;
			break;
		case 2:
			_angle = newValue;
			_force = Vec2f.angled(_angle) * _acceleration;
			break;
		case 3:
			_acceleration = newValue;
			_force = Vec2f.angled(_angle) * _acceleration;
			break;
		default:
			throw new Exception("Filter property out of range");
		}
	}

	protected override void updateParticle(Particle particle, float deltaTime) {
		particle.velocity += _force * deltaTime;
	}

	override FilterProperty[] getProperties() const {
		return [
			tuple("Longueur", 2f, 2000f, 1998u),
			tuple("Hauteur", 2f, 2000f, 1998u),
			tuple("Angle", 0f, 360f, 360u),
			tuple("Accel.", 0f, 0.5f, 1000u)
			];
	}

	override FilterDisplay getDisplay() const {
		return tuple("Force", _isCircle, _size, true, cast(const Vec2f)(_force * 1000f), Color.red);
	}
}

//SetSpeed Filter
final class SetSpeedFilterCircle: ParticleFilter {
	private	{
		float _speed = 0f; 
	}

	this() {
		_id = 2;
		_nbProperties = 2U;
		_isCircle = true;
	}

	override float property(uint id) const {
		switch(id) {
		case 0:
			return _size.x;
		case 1:
			return _speed;
		default:
			throw new Exception("Filter property out of range");
		}
	}

	override void property(uint id, float newValue) {
		switch(id) {
		case 0:
			_size.x = newValue;
			_size.y = newValue;
			break;
		case 1:
			_speed = newValue;
			break;
		default:
			throw new Exception("Filter property out of range");
		}
	}

	protected override void updateParticle(Particle particle, float deltaTime) {
		particle.velocity = particle.velocity.normalized * _speed;
	}

	override FilterProperty[] getProperties() const {
		return [
			tuple("Rayon", 1f, 1000f, 999u),
			tuple("Vitesse", 0f, 10f, 200u)
			];
	}

	override FilterDisplay getDisplay() const {
		return tuple("Vitesse: " ~ to!string(_speed), _isCircle, _size, false, cast(const Vec2f)Vec2f.zero, Color.green);
	}
}

final class SetSpeedFilterRect: ParticleFilter {
	private	{
		float _speed = 0f; 
	}

	this() {
		_id = 3;
		_nbProperties = 3U;
		_isCircle = false;
	}

	override float property(uint id) const {
		switch(id) {
		case 0:
			return _size.x;
		case 1:
			return _size.y;
		case 2:
			return _speed;
		default:
			throw new Exception("Filter property out of range");
		}
	}

	override void property(uint id, float newValue) {
		switch(id) {
		case 0:
			_size.x = newValue;
			break;
		case 1:
			_size.y = newValue;
			break;
		case 2:
			_speed = newValue;
			break;
		default:
			throw new Exception("Filter property out of range");
		}
	}

	protected override void updateParticle(Particle particle, float deltaTime) {
		particle.velocity = particle.velocity.normalized * _speed;
	}

	override FilterProperty[] getProperties() const {
		return [
			tuple("Longueur", 2f, 2000f, 1998u),
			tuple("Hauteur", 2f, 2000f, 1998u),
			tuple("Vitesse", 0f, 10f, 200u)
			];
	}

	override FilterDisplay getDisplay() const {
		return tuple("Vitesse: " ~ to!string(_speed), _isCircle, _size, false, cast(const Vec2f)Vec2f.zero, Color.green);
	}
}

//SpeedLimit Filter
final class SpeedLimitFilterCircle: ParticleFilter {
	private	{
		float _limit = 0f; 
	}

	this() {
		_id = 4;
		_nbProperties = 2U;
		_isCircle = true;
	}

	override float property(uint id) const {
		switch(id) {
		case 0:
			return _size.x;
		case 1:
			return _limit;
		default:
			throw new Exception("Filter property out of range");
		}
	}

	override void property(uint id, float newValue) {
		switch(id) {
		case 0:
			_size.x = newValue;
			_size.y = newValue;
			break;
		case 1:
			_limit = newValue;
			break;
		default:
			throw new Exception("Filter property out of range");
		}
	}

	protected override void updateParticle(Particle particle, float deltaTime) {
		if(particle.velocity.lengthSquared > _limit * _limit)
			particle.velocity = particle.velocity.normalized * _limit;
	}

	override FilterProperty[] getProperties() const {
		return [
			tuple("Rayon", 1f, 1000f, 999u),
			tuple("Limite", 0f, 10f, 200u)
			];
	}

	override FilterDisplay getDisplay() const {
		return tuple("Vit. Limite: " ~ to!string(_limit), _isCircle, _size, false, cast(const Vec2f)Vec2f.zero, Color.green);
	}
}

final class SpeedLimitFilterRect: ParticleFilter {
	private	{
		float _limit = 0f; 
	}

	this() {
		_id = 5;
		_nbProperties = 3U;
		_isCircle = false;
	}

	override float property(uint id) const {
		switch(id) {
		case 0:
			return _size.x;
		case 1:
			return _size.y;
		case 2:
			return _limit;
		default:
			throw new Exception("Filter property out of range");
		}
	}

	override void property(uint id, float newValue) {
		switch(id) {
		case 0:
			_size.x = newValue;
			break;
		case 1:
			_size.y = newValue;
			break;
		case 2:
			_limit = newValue;
			break;
		default:
			throw new Exception("Filter property out of range");
		}
	}

	protected override void updateParticle(Particle particle, float deltaTime) {
		if(particle.velocity.lengthSquared > _limit * _limit)
			particle.velocity = particle.velocity.normalized * _limit;
	}

	override FilterProperty[] getProperties() const {
		return [
			tuple("Longueur", 2f, 2000f, 1998u),
			tuple("Hauteur", 2f, 2000f, 1998u),
			tuple("Limite", 0f, 10f, 200u)
			];
	}

	override FilterDisplay getDisplay() const {
		return tuple("Vit. Limite: " ~ to!string(_limit), _isCircle, _size, false, cast(const Vec2f)Vec2f.zero, Color.green);
	}
}

//Attract Filter
final class AttractFilterCircle: ParticleFilter {
	private	{
		float _acceleration = 0f;
	}

	this() {
		_id = 6;
		_nbProperties = 2U;
		_isCircle = true;
	}

	override float property(uint id) const {
		switch(id) {
		case 0:
			return _size.x;
		case 1:
			return _acceleration;
		default:
			throw new Exception("Filter property out of range");
		}
	}

	override void property(uint id, float newValue) {
		switch(id) {
		case 0:
			_size.x = newValue;
			_size.y = newValue;
			break;
		case 1:
			_acceleration = newValue;
			break;
		default:
			throw new Exception("Filter property out of range");
		}
	}

	protected override void updateParticle(Particle particle, float deltaTime) {
		particle.velocity += (_position - particle.position).normalized * _acceleration * deltaTime;
	}

	override FilterProperty[] getProperties() const {
		return [
			tuple("Rayon", 1f, 1000f, 999u),
			tuple("Accel.", 0f, 0.5f, 1000u)
			];
	}

	override FilterDisplay getDisplay() const {
		return tuple("Attracteur", _isCircle, _size, false, cast(const Vec2f)Vec2f.zero, Color.blue);
	}
}

final class AttractFilterRect: ParticleFilter {
	private	{
		float _acceleration = 0f;
	}

	this() {
		_id = 7;
		_nbProperties = 3U;
		_isCircle = false;
	}

	override float property(uint id) const {
		switch(id) {
		case 0:
			return _size.x;
		case 1:
			return _size.y;
		case 2:
			return _acceleration;
		default:
			throw new Exception("Filter property out of range");
		}
	}

	override void property(uint id, float newValue) {
		switch(id) {
		case 0:
			_size.x = newValue;
			break;
		case 1:
			_size.y = newValue;
			break;
		case 2:
			_acceleration = newValue;
			break;
		default:
			throw new Exception("Filter property out of range");
		}
	}

	protected override void updateParticle(Particle particle, float deltaTime) {
		particle.velocity += (_position - particle.position).normalized * _acceleration * deltaTime;
	}

	override FilterProperty[] getProperties() const {
		return [
			tuple("Longueur", 2f, 2000f, 1998u),
			tuple("Hauteur", 2f, 2000f, 1998u),
			tuple("Accel.", 0f, 0.5f, 1000u)
			];
	}

	override FilterDisplay getDisplay() const {
		return tuple("Attracteur", _isCircle, _size, false, cast(const Vec2f)Vec2f.zero, Color.blue);
	}
}

//Repulse Filter
final class RepulseFilterCircle: ParticleFilter {
	private	{
		float _acceleration = 0f;
	}

	this() {
		_id = 8;
		_nbProperties = 2U;
		_isCircle = true;
	}

	override float property(uint id) const {
		switch(id) {
		case 0:
			return _size.x;
		case 1:
			return _acceleration;
		default:
			throw new Exception("Filter property out of range");
		}
	}

	override void property(uint id, float newValue) {
		switch(id) {
		case 0:
			_size.x = newValue;
			_size.y = newValue;
			break;
		case 1:
			_acceleration = newValue;
			break;
		default:
			throw new Exception("Filter property out of range");
		}
	}

	protected override void updateParticle(Particle particle, float deltaTime) {
		particle.velocity += (particle.position - _position).normalized * _acceleration * deltaTime;
	}

	override FilterProperty[] getProperties() const {
		return [
			tuple("Rayon", 1f, 1000f, 999u),
			tuple("Accel.", 0f, 0.5f, 1000u)
			];
	}

	override FilterDisplay getDisplay() const {
		return tuple("Répulseur", _isCircle, _size, false, cast(const Vec2f)Vec2f.zero, Color.cyan);
	}
}

final class RepulseFilterRect: ParticleFilter {
	private	{
		float _acceleration = 0f;
	}

	this() {
		_id = 9;
		_nbProperties = 3U;
		_isCircle = false;
	}

	override float property(uint id) const {
		switch(id) {
		case 0:
			return _size.x;
		case 1:
			return _size.y;
		case 2:
			return _acceleration;
		default:
			throw new Exception("Filter property out of range");
		}
	}

	override void property(uint id, float newValue) {
		switch(id) {
		case 0:
			_size.x = newValue;
			break;
		case 1:
			_size.y = newValue;
			break;
		case 2:
			_acceleration = newValue;
			break;
		default:
			throw new Exception("Filter property out of range");
		}
	}

	protected override void updateParticle(Particle particle, float deltaTime) {
		particle.velocity += (particle.position - _position).normalized * _acceleration * deltaTime;
	}

	override FilterProperty[] getProperties() const {
		return [
			tuple("Longueur", 2f, 2000f, 1998u),
			tuple("Hauteur", 2f, 2000f, 1998u),
			tuple("Accel.", 0f, 0.5f, 1000u)
			];
	}

	override FilterDisplay getDisplay() const {
		return tuple("Répulseur", _isCircle, _size, false, cast(const Vec2f)Vec2f.zero, Color.cyan);
	}
}

//Destructor Filter
final class DestructorFilterCircle: ParticleFilter {
	this() {
		_id = 10;
		_nbProperties = 1U;
		_isCircle = true;
	}

	override float property(uint id) const {
		switch(id) {
		case 0:
			return _size.x;
		default:
			throw new Exception("Filter property out of range");
		}
	}

	override void property(uint id, float newValue) {
		switch(id) {
		case 0:
			_size.x = newValue;
			_size.y = newValue;
			break;
		default:
			throw new Exception("Filter property out of range");
		}
	}

	protected override void updateParticle(Particle particle, float deltaTime) {
		particle.timeToLive = 0f;
	}

	override FilterProperty[] getProperties() const {
		return [
			tuple("Rayon", 1f, 1000f, 999u)
			];
	}

	override FilterDisplay getDisplay() const {
		return tuple("Destructeur", _isCircle, _size, false, cast(const Vec2f)Vec2f.zero, Color.silver);
	}
}

final class DestructorFilterRect: ParticleFilter {
	this() {
		_id = 11;
		_nbProperties = 2U;
		_isCircle = false;
	}

	override float property(uint id) const {
		switch(id) {
		case 0:
			return _size.x;
		case 1:
			return _size.y;
		default:
			throw new Exception("Filter property out of range");
		}
	}

	override void property(uint id, float newValue) {
		switch(id) {
		case 0:
			_size.x = newValue;
			break;
		case 1:
			_size.y = newValue;
			break;
		default:
			throw new Exception("Filter property out of range");
		}
	}

	protected override void updateParticle(Particle particle, float deltaTime) {
		particle.timeToLive = 0f;
	}

	override FilterProperty[] getProperties() const {
		return [
			tuple("Longueur", 2f, 2000f, 1998u),
			tuple("Hauteur", 2f, 2000f, 1998u)
			];
	}

	override FilterDisplay getDisplay() const {
		return tuple("Destructeur", _isCircle, _size, false, cast(const Vec2f)Vec2f.zero, Color.silver);
	}
}

//SetScale Filter
final class SetScaleFilterCircle: ParticleFilter {
	private	float _scale = 1f;

	this() {
		_id = 12;
		_nbProperties = 2U;
		_isCircle = true;
	}

	override float property(uint id) const {
		switch(id) {
		case 0:
			return _size.x;
		case 1:
			return _scale;
		default:
			throw new Exception("Filter property out of range");
		}
	}

	override void property(uint id, float newValue) {
		switch(id) {
		case 0:
			_size.x = newValue;
			_size.y = newValue;
			break;
		case 1:
			_scale = newValue;
			break;
		default:
			throw new Exception("Filter property out of range");
		}
	}

	protected override void updateParticle(Particle particle, float deltaTime) {
		particle.scale = _scale;
	}

	override FilterProperty[] getProperties() const {
		return [
			tuple("Rayon", 1f, 1000f, 999u),
			tuple("Taille", 0f, 10f, 1000u)
			];
	}

	override FilterDisplay getDisplay() const {
		return tuple("Taille", _isCircle, _size, false, cast(const Vec2f)Vec2f.zero, Color.olive);
	}
}

final class SetScaleFilterRect: ParticleFilter {
	private	float _scale = 1f;

	this() {
		_id = 13;
		_nbProperties = 3U;
		_isCircle = false;
	}

	override float property(uint id) const {
		switch(id) {
		case 0:
			return _size.x;
		case 1:
			return _size.y;
		case 2:
			return _scale;
		default:
			throw new Exception("Filter property out of range");
		}
	}

	override void property(uint id, float newValue) {
		switch(id) {
		case 0:
			_size.x = newValue;
			break;
		case 1:
			_size.y = newValue;
			break;
		case 2:
			_scale = newValue;
			break;
		default:
			throw new Exception("Filter property out of range");
		}
	}

	protected override void updateParticle(Particle particle, float deltaTime) {
		particle.scale = _scale;
	}

	override FilterProperty[] getProperties() const {
		return [
			tuple("Longueur", 2f, 2000f, 1998u),
			tuple("Hauteur", 2f, 2000f, 1998u),
			tuple("Taille", 0f, 10f, 1000u)
			];
	}

	override FilterDisplay getDisplay() const {
		return tuple("Taille", _isCircle, _size, false, cast(const Vec2f)Vec2f.zero, Color.olive);
	}
}

//MixScale Filter
final class MixScaleFilterCircle: ParticleFilter {
	private	{
		float _scale = 1f, _blend = 1f;
	}

	this() {
		_id = 14;
		_nbProperties = 3U;
		_isCircle = true;
	}

	override float property(uint id) const {
		switch(id) {
		case 0:
			return _size.x;
		case 1:
			return _scale;
		case 2:
			return _blend;
		default:
			throw new Exception("Filter property out of range");
		}
	}

	override void property(uint id, float newValue) {
		switch(id) {
		case 0:
			_size.x = newValue;
			_size.y = newValue;
			break;
		case 1:
			_scale = newValue;
			break;
		case 2:
			_blend = newValue;
			break;
		default:
			throw new Exception("Filter property out of range");
		}
	}

	protected override void updateParticle(Particle particle, float deltaTime) {
		particle.scale = lerp(particle.scale, _scale, _blend * deltaTime);
	}

	override FilterProperty[] getProperties() const {
		return [
			tuple("Rayon", 1f, 1000f, 999u),
			tuple("Taille", 0f, 10f, 1000u),
			tuple("Mélange", 0.0001f, 0.1f, 1000u)
			];
	}

	override FilterDisplay getDisplay() const {
		return tuple("M.Taille", _isCircle, _size, false, cast(const Vec2f)Vec2f.zero, Color.navy);
	}
}

final class MixScaleFilterRect: ParticleFilter {
	private	{
		float _scale = 1f, _blend = 1f;
	}

	this() {
		_id = 15;
		_nbProperties = 4U;
		_isCircle = false;
	}

	override float property(uint id) const {
		switch(id) {
		case 0:
			return _size.x;
		case 1:
			return _size.y;
		case 2:
			return _scale;
		case 3:
			return _blend;
		default:
			throw new Exception("Filter property out of range");
		}
	}

	override void property(uint id, float newValue) {
		switch(id) {
		case 0:
			_size.x = newValue;
			break;
		case 1:
			_size.y = newValue;
			break;
		case 2:
			_scale = newValue;
			break;
		case 3:
			_blend = newValue;
			break;
		default:
			throw new Exception("Filter property out of range");
		}
	}

	protected override void updateParticle(Particle particle, float deltaTime) {
		particle.scale = lerp(particle.scale, _scale, _blend * deltaTime);
	}

	override FilterProperty[] getProperties() const {
		return [
			tuple("Longueur", 2f, 2000f, 1998u),
			tuple("Hauteur", 2f, 2000f, 1998u),
			tuple("Taille", 0f, 10f, 1000u),
			tuple("Mélange", 0.0001f, 0.1f, 1000u)
			];
	}

	override FilterDisplay getDisplay() const {
		return tuple("M.Taille", _isCircle, _size, false, cast(const Vec2f)Vec2f.zero, Color.navy);
	}
}

//SetColor Filter
final class SetColorFilterCircle: ParticleFilter {
	private	Color _color;

	this() {
		_id = 16;
		_nbProperties = 5U;
		_isCircle = true;
	}

	override float property(uint id) const {
		switch(id) {
		case 0:
			return _size.x;
		case 1:
			return _color.r;
		case 2:
			return _color.g;
		case 3:
			return _color.b;
		case 4:
			return _color.a;
		default:
			throw new Exception("Filter property out of range");
		}
	}

	override void property(uint id, float newValue) {
		switch(id) {
		case 0:
			_size.x = newValue;
			_size.y = newValue;
			break;
		case 1:
			_color.r = newValue;
			break;
		case 2:
			_color.g = newValue;
			break;
		case 3:
			_color.b = newValue;
			break;
		case 4:
			_color.a = newValue;
			break;
		default:
			throw new Exception("Filter property out of range");
		}
	}

	protected override void updateParticle(Particle particle, float deltaTime) {
		particle.color = _color;
	}

	override FilterProperty[] getProperties() const {
		return [
			tuple("Rayon", 1f, 1000f, 999u),
			tuple("Rouge", 0f, 1f, 256u),
			tuple("Vert", 0f, 1f, 256u),
			tuple("Bleu", 0f, 1f, 256u),
			tuple("Alpha", 0f, 1f, 256u)
			];
	}

	override FilterDisplay getDisplay() const {
		Color color = _color;
		color.a = 1f;
		return tuple("Couleur", _isCircle, _size, false, cast(const Vec2f)Vec2f.zero, cast(const Color)color);
	}
}

final class SetColorFilterRect: ParticleFilter {
	private	Color _color;

	this() {
		_id = 17;
		_nbProperties = 6U;
		_isCircle = false;
	}

	override float property(uint id) const {
		switch(id) {
		case 0:
			return _size.x;
		case 1:
			return _size.y;
		case 2:
			return _color.r;
		case 3:
			return _color.g;
		case 4:
			return _color.b;
		case 5:
			return _color.a;
		default:
			throw new Exception("Filter property out of range");
		}
	}

	override void property(uint id, float newValue) {
		switch(id) {
		case 0:
			_size.x = newValue;
			break;
		case 1:
			_size.y = newValue;
			break;
		case 2:
			_color.r = newValue;
			break;
		case 3:
			_color.g = newValue;
			break;
		case 4:
			_color.b = newValue;
			break;
		case 5:
			_color.a = newValue;
			break;
		default:
			throw new Exception("Filter property out of range");
		}
	}

	protected override void updateParticle(Particle particle, float deltaTime) {
		particle.color = _color;
	}

	override FilterProperty[] getProperties() const {
		return [
			tuple("Longueur", 2f, 2000f, 1998u),
			tuple("Hauteur", 2f, 2000f, 1998u),
			tuple("Rouge", 0f, 1f, 256u),
			tuple("Vert", 0f, 1f, 256u),
			tuple("Bleu", 0f, 1f, 256u),
			tuple("Alpha", 0f, 1f, 256u)
			];
	}

	override FilterDisplay getDisplay() const {
		Color color = _color;
		color.a = 1f;
		return tuple("Couleur", _isCircle, _size, false, cast(const Vec2f)Vec2f.zero, cast(const Color)color);
	}
}


//MixColor Filter
final class MixColorFilterCircle: ParticleFilter {
	private	{
		Color _color;
		float _blend = 1f;
	}

	this() {
		_id = 18;
		_nbProperties = 6U;
		_isCircle = true;
	}

	override float property(uint id) const {
		switch(id) {
		case 0:
			return _size.x;
		case 1:
			return _color.r;
		case 2:
			return _color.g;
		case 3:
			return _color.b;
		case 4:
			return _color.a;
		case 5:
			return _blend;
		default:
			throw new Exception("Filter property out of range");
		}
	}

	override void property(uint id, float newValue) {
		switch(id) {
		case 0:
			_size.x = newValue;
			_size.y = newValue;
			break;
		case 1:
			_color.r = newValue;
			break;
		case 2:
			_color.g = newValue;
			break;
		case 3:
			_color.b = newValue;
			break;
		case 4:
			_color.a = newValue;
			break;
		case 5:
			_blend = newValue;
			break;
		default:
			throw new Exception("Filter property out of range");
		}
	}

	protected override void updateParticle(Particle particle, float deltaTime) {
		particle.color = lerp(particle.color, _color, _blend * deltaTime);
	}

	override FilterProperty[] getProperties() const {
		return [
			tuple("Rayon", 1f, 1000f, 999u),
			tuple("Rouge", 0f, 1f, 256u),
			tuple("Vert", 0f, 1f, 256u),
			tuple("Bleu", 0f, 1f, 256u),
			tuple("Alpha", 0f, 1f, 256u),
			tuple("Mélange", .001f, .1f, 1000u)
			];
	}

	override FilterDisplay getDisplay() const {
		Color color = _color;
		color.a = 1f;
		return tuple("Couleur", _isCircle, _size, false, cast(const Vec2f)Vec2f.zero, cast(const Color)color);
	}
}

final class MixColorFilterRect: ParticleFilter {
	private	{
		Color _color;
		float _blend = 1f;
	}

	this() {
		_id = 19;
		_nbProperties = 7U;
		_isCircle = false;
	}

	override float property(uint id) const {
		switch(id) {
		case 0:
			return _size.x;
		case 1:
			return _size.y;
		case 2:
			return _color.r;
		case 3:
			return _color.g;
		case 4:
			return _color.b;
		case 5:
			return _color.a;
		case 6:
			return _blend;
		default:
			throw new Exception("Filter property out of range");
		}
	}

	override void property(uint id, float newValue) {
		switch(id) {
		case 0:
			_size.x = newValue;
			break;
		case 1:
			_size.y = newValue;
			break;
		case 2:
			_color.r = newValue;
			break;
		case 3:
			_color.g = newValue;
			break;
		case 4:
			_color.b = newValue;
			break;
		case 5:
			_color.a = newValue;
			break;
		case 6:
			_blend = newValue;
			break;
		default:
			throw new Exception("Filter property out of range");
		}
	}

	protected override void updateParticle(Particle particle, float deltaTime) {
		particle.color = lerp(particle.color, _color, _blend * deltaTime);
	}

	override FilterProperty[] getProperties() const {
		return [
			tuple("Longueur", 2f, 2000f, 1998u),
			tuple("Hauteur", 2f, 2000f, 1998u),
			tuple("Rouge", 0f, 1f, 256u),
			tuple("Vert", 0f, 1f, 256u),
			tuple("Bleu", 0f, 1f, 256u),
			tuple("Alpha", 0f, 1f, 256u),
			tuple("Mélange", .001f, .1f, 1000u)
			];
	}

	override FilterDisplay getDisplay() const {
		Color color = _color;
		color.a = 1f;
		return tuple("Couleur", _isCircle, _size, false, cast(const Vec2f)Vec2f.zero, cast(const Color)color);
	}
}