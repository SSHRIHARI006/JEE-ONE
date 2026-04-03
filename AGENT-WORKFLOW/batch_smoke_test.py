from logic.views.batch_view import handle_batch_request


result = handle_batch_request(batch_size=5)

print("BATCH_SMOKE_TEST_OK")
print("SUMMARY", result.get("summary"))
print("ASSIGNMENTS", len(result.get("assignments", [])))
for item in result.get("assignments", []):
    print(item)