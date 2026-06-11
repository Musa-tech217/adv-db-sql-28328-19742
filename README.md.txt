

# UniHospital

## Developed By
- Musa Alie Zain ID 28328
- Zainab Sesay ID 19742

## 5.3 (c) Explain when you would choose SNAPSHOT isolation over SERIALIZABLE in a hospital system that uses SQL Server. we usually prefer SNAPSHOT isolation for daily tasks. This is when lots of people need to look at information at the same time, like checking patient files, looking up appointments, or running reports. SNAPSHOT helps the system run smoothly by allowing people to read data without slowing things down by locking tables. For very important tasks that need perfect accuracy, like assigning hospital beds, managing medicine supplies, or scheduling operations, we use SERIALIZABLE isolation. This level offers stronger data protection and makes sure everything is consistent. The downside is that it can make the system slower because it locks data more heavily, and this can sometimes lead to issues where two things are waiting for each other, called deadlocks. So, SNAPSHOT is better when many users are just viewing data, making the system faster. But for critical jobs, getting the numbers exactly right is the most important thing; SERIALIZABLE is the way to go.
