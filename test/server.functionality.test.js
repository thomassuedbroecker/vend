var request = require('supertest');

describe('loading express', function () {
  var server;
  beforeEach(function () {   
    delete require.cache[require.resolve('../server')];
    server = require('../server');
  });

  afterEach(function () {
    server.close();
  });

  it('responds to "/" with json', function (done) {
  request(server)
    .get('/')
    .set('Accept', 'application/json')
    .expect('Content-Type', /json/)
    // .expect(401, done) // local
    .expect(200, done) // integration
  });

  it('responds to "/health" with json', function (done) {
    request(server)
      .get('/health')
      .set('Accept', 'application/json')
      .expect('Content-Type', /json/)
      .expect(200, done)
    });
});