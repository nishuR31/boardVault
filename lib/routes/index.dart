import "package:go_router/go_router.dart";
import "/pages/home.dart";
import "/pages/about.dart";
import "/pages/boards.dart";
// import "/pages/board.dart";
import "/pages/privacy.dart";
import "/pages/terms.dart";
import "/pages/faqs.dart";
import "/pages/health.dart";
import "/pages/error.dart";

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(path: "/about", builder: (context, state) => const About()),
    GoRoute(path: "/", builder: (context, state) => const Home()),
    GoRoute(path: "/boards", builder: (context, state) => const Boards()),
    // GoRoute(path:"/boards/:name",builder:(context,state){final name=state.pathParameters["name"];
    //  return Board(name:name!)}),
    GoRoute(path: "/privacy", builder: (context, state) => const Privacy()),
    GoRoute(path: "/health", builder: (context, state) => const Health()),
    GoRoute(path: "/terms", builder: (context, state) => const Terms()),
    GoRoute(path: "/faqs", builder: (context, state) => const FAQs()),
    GoRoute(
      path: '/:path(.*)',
      builder: (context, state) => Error(route: state.uri.path),
    ),
  ],
);
