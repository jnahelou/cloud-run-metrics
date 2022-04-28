import mock

import main


def test_traces():
    exporter = mock.Mock()
    main.configure_exporter(exporter)
    client = main.app.test_client()
    resp = client.get("/")
    assert resp.status_code == 200
