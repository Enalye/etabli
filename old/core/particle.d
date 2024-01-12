/**
    Particle    

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module etabli.core.particle;

import std.random;

import etabli.render;

import etabli.core.vec2;
import etabli.core.color;
import etabli.core.stream;
import etabli.core.indexedarray;
import etabli.core.particlefilter;

/+
class Particle {
	Vec2f position, velocity;
	float time, timeToLive;
	float scale, spriteAngle, spriteAngleSpeed;
	Color color;
}

class ParticleSource {
	IndexedArray!(Particle, 5000u) particles;
	IndexedArray!(ParticleFilter, 20u) filters;
	Sprite sprite;
	Vec2f position = Vec2f.zero;
	
	private {
		float _timeUntilNextSpawn = 0f;
	}

	float timeToLive = 1f, timeToLiveDelta = 0f;
	float spawnDelay = 1f, spawnDelayDelta = 0f;
	float scale = 1f, radius = 1f, angle = 0f, angleDelta = 0f, speed = 1f, speedDelta = 0f;

	this() {
		particles = new IndexedArray!(Particle, 5000u);
		filters = new IndexedArray!(ParticleFilter, 20u);
	}

	void update(float deltaTime) {
		foreach(Particle particle, uint index; particles) {
			particle.time += deltaTime;
			float t = particle.time / particle.timeToLive;
			if(t > 1f)
				particles.markInternalForRemoval(index);
			else {
				foreach(filter; filters) {
					filter.apply(particle, deltaTime);
				}

				particle.position += particle.velocity * deltaTime;
				particle.spriteAngle += particle.spriteAngleSpeed * deltaTime;
			}
		}

		float random(float step, float delta) {
			if(delta == 0f)
				return step;
			return uniform!"[]"((1f - delta) * step, (1f + delta) * step);
		}

		float random2(float step, float delta) {
			if(delta == 0f)
				return step;
			return uniform!"[]"(step - delta / 2f, step + delta / 2f);
		}

		particles.sweepMarkedData();
		_timeUntilNextSpawn -= deltaTime;
		if(_timeUntilNextSpawn < 0f) {
			_timeUntilNextSpawn = random(spawnDelay, spawnDelayDelta);

			auto particle = new Particle;
			particle.position = position + Vec2f.angled(uniform(0f, 360f)) * (radius > 1f ? uniform(0f, radius) : 1f);
			particle.time = 0f;
			particle.timeToLive = random(timeToLive, timeToLiveDelta);
			if(particle.timeToLive == 0f)
				particle.timeToLive = 1f;

			float angle = random2(angle, angleDelta);
			particle.velocity = Vec2f.angled(angle) * random(speed, speedDelta);
			particle.scale = scale;

			particle.color = Color.white;
			particles.push(particle);
		}
	}

	void draw() {
		if(sprite.texture is null) {
			foreach(Particle particle, uint index; particles) {
				float t = particle.time / particle.timeToLive;
				drawFilledRect(particle.position, Vec2f.one * particle.scale, particle.color);
				
			}
		}
		else {	
			foreach(Particle particle, uint index; particles) {
				float t = particle.time / particle.timeToLive;
				sprite.scale = Vec2f.one * particle.scale;
				//sprite.angle = particle.spriteAngle;
				sprite.color = particle.color;
				sprite.draw(particle.position);
			}
		}
	}

	void save(OutStream stream) {
		stream.write!float(timeToLive);
		stream.write!float(timeToLiveDelta);
		stream.write!float(spawnDelay);
		stream.write!float(spawnDelayDelta);
		stream.write!float(scale);
		stream.write!float(radius);
		stream.write!float(angle);
		stream.write!float(angleDelta);
		stream.write!float(speed);
		stream.write!float(speedDelta);
	}

	void load(InStream stream) {
		timeToLive = stream.read!float();
		timeToLiveDelta = stream.read!float();
		spawnDelay = stream.read!float();
		spawnDelayDelta = stream.read!float();
		scale = stream.read!float();
		radius = stream.read!float();
		angle = stream.read!float();
		angleDelta = stream.read!float();
		speed = stream.read!float();
		speedDelta = stream.read!float();
	}
}+/
