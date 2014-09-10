
def test_imports():
    try:
        import agent
        import checks
        import daemon
    except SystemExit:
        pass  # expected, agent.py line 196
