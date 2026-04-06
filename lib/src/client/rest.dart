// purpose: Assemble the REST DTO library so client code can depend on explicit wire models without committing to a concrete HTTP package.
// responsibilities: Bind the shared REST envelope, request types, response types, and transport interfaces into one library.
// architecture notes: This library uses part files to keep request and response concerns separate while still sharing private decoding helpers.
import 'error.dart';
import 'model.dart';

part 'rest_common.dart';
part 'rest_interfaces.dart';
part 'rest_requests.dart';
part 'rest_responses.dart';
