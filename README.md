### Lambda test
tf init
tf apply

Invoke from cmd:

aws lambda invoke --function-name arn:aws:lambda:eu-west-1:530822941441:function:Test_Lambda --payload '{"key1": "John Smith"}' --cli-binary-format raw-in-base64-out ./output.lam