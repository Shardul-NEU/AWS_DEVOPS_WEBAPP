import {assert} from 'chai';
import {add} from './unittest.js';

describe('add', function() {
  it('should return the sum of two numbers', function() {
    assert.equal(add(2, 3), 5);
    assert.equal(add(0, 0), 0);
    assert.equal(add(-2, 2), 0);
  });

  it('should return NaN when called with non-numeric arguments', function() {
    assert(isNaN(add('foo', 'bar')));
    assert(isNaN(add(2, 'bar')));
    assert(isNaN(add('foo', 3)));
  });
});