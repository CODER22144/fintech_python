def generate_error_message(exception):
    # TODO: GENERATE ERROR MESSAGE PROEPERLY
    return {
            "status" : False,
            "errorCode" : exception.args[0] if exception.args else 9000,
            "message" : str(exception)
        }